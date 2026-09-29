import Foundation

struct CodeTestCase: Identifiable {
    let id: String
    let name: String
    let input: String
    let expectedOutput: String
    let arguments: [String]

    init(
        id: String,
        name: String,
        input: String,
        expectedOutput: String,
        arguments: [String] = []
    ) {
        self.id = id
        self.name = name
        self.input = input
        self.expectedOutput = expectedOutput
        self.arguments = arguments
    }
}

struct CodeRunResult: Codable {
    let succeeded: Bool
    let passed: Bool
    let stdout: String
    let stderr: String
    let exitCode: Int32
    let timedOut: Bool
    let message: String
}

enum CodeExecutionService {
    nonisolated static func validationError(
        code: String,
        input: String,
        arguments: [String]
    ) -> String? {
        guard code.utf8.count <= 200_000 else {
            return "代码不能超过 200 KB。"
        }
        guard input.utf8.count <= 64_000 else {
            return "标准输入不能超过 64 KB。"
        }
        guard arguments.count <= 16 else {
            return "命令行参数不能超过 16 个。"
        }
        guard arguments.allSatisfy({ $0.utf8.count <= 256 }) else {
            return "单个命令行参数不能超过 256 字节。"
        }
        return nil
    }

    static func run(
        code: String,
        language: String,
        input: String,
        arguments: [String] = [],
        expectedOutput: String
    ) async -> CodeRunResult {
        if let validationError = validationError(code: code, input: input, arguments: arguments) {
            return .remoteFailure(validationError)
        }

        #if os(macOS)
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = runOnMac(
                    code: code,
                    language: language,
                    input: input,
                    arguments: arguments,
                    expectedOutput: expectedOutput
                )
                DispatchQueue.main.async {
                    continuation.resume(returning: result)
                }
            }
        }
        #else
        return await RemoteCodeExecutionService.run(
            code: code,
            language: language,
            input: input,
            arguments: arguments,
            expectedOutput: expectedOutput
        )
        #endif
    }

    #if os(macOS)
    private static func runOnMac(
        code: String,
        language: String,
        input: String,
        arguments: [String],
        expectedOutput: String
    ) -> CodeRunResult {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
            .appendingPathComponent("cs-self-study-\(UUID().uuidString)", isDirectory: true)

        do {
            try fileManager.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
        } catch {
            return failure("无法创建临时编译目录：\(error.localizedDescription)")
        }

        defer { try? fileManager.removeItem(at: directory) }

        let normalizedLanguage = language.lowercased()
        let sourceURL: URL
        let compiler: String
        let compilerArguments: [String]
        let executableURL: URL

        if normalizedLanguage == "swift" {
            sourceURL = directory.appendingPathComponent("main.swift")
            compiler = "/usr/bin/swiftc"
            executableURL = directory.appendingPathComponent("program")
            compilerArguments = ["-o", executableURL.path, sourceURL.path]
        } else {
            sourceURL = directory.appendingPathComponent("main.c")
            compiler = "/usr/bin/clang"
            executableURL = directory.appendingPathComponent("program")
            compilerArguments = ["-Wall", "-Wextra", "-O0", "-o", executableURL.path, sourceURL.path]
        }

        do {
            try code.write(to: sourceURL, atomically: true, encoding: .utf8)
        } catch {
            return failure("无法写入源代码：\(error.localizedDescription)")
        }

        let compileResult = runProcess(
            executable: compiler,
            arguments: compilerArguments,
            directory: directory,
            input: "",
            timeout: 30,
            enforceResourceLimits: false,
            isExecution: false
        )

        guard compileResult.exitCode == 0 else {
            return CodeRunResult(
                succeeded: false,
                passed: false,
                stdout: compileResult.stdout,
                stderr: compileResult.stderr,
                exitCode: compileResult.exitCode,
                timedOut: compileResult.timedOut,
                message: compileResult.timedOut ? "编译超时。" : "编译失败，请先阅读 stderr。"
            )
        }

        let runResult = runProcess(
            executable: executableURL.path,
            arguments: arguments,
            directory: directory,
            input: input,
            timeout: 5,
            enforceResourceLimits: true,
            isExecution: true
        )

        guard runResult.exitCode == 0 else {
            return CodeRunResult(
                succeeded: false,
                passed: false,
                stdout: runResult.stdout,
                stderr: runResult.stderr,
                exitCode: runResult.exitCode,
                timedOut: runResult.timedOut,
                message: runResult.timedOut ? "程序运行超时。" : "程序以非零状态退出。"
            )
        }

        let passed = normalized(runResult.stdout) == normalized(expectedOutput)
        return CodeRunResult(
            succeeded: true,
            passed: passed,
            stdout: runResult.stdout,
            stderr: runResult.stderr,
            exitCode: runResult.exitCode,
            timedOut: false,
            message: passed ? "通过测试用例。" : "程序运行成功，但输出与预期不一致。"
        )
    }

    private static func runProcess(
        executable: String,
        arguments: [String],
        directory: URL,
        input: String,
        timeout: TimeInterval,
        enforceResourceLimits: Bool,
        isExecution: Bool
    ) -> CodeProcessResult {
        let profileURL = directory.appendingPathComponent("sandbox.sb")
        let runnerURL = directory.appendingPathComponent("runner")
        let runnerSourceURL = directory.appendingPathComponent("runner.c")
        let stdoutURL = directory.appendingPathComponent("stdout.txt")
        let stderrURL = directory.appendingPathComponent("stderr.txt")

        let executionDenies = isExecution ? """
        (deny process-fork)
        (deny process-exec* (literal "/bin/sh"))
        (deny process-exec* (literal "/bin/zsh"))
        (deny process-exec* (literal "/usr/bin/env"))
        (deny process-exec* (literal "/usr/bin/python3"))
        """ : ""

        let profile = """
        (version 1)
        (allow default)
        (deny network*)
        (deny file-read* (subpath "/Users"))
        (deny file-write* (subpath "/Users"))
        (deny file-write* (subpath "/Volumes"))
        (deny file-write* (subpath "/System"))
        (deny file-write* (subpath "/Library"))
        (deny file-write* (subpath "/Applications"))
        (deny file-write* (subpath "/private/etc"))
        (deny file-write* (subpath "/private/var/db"))
        \(executionDenies)
        """

        let runnerSource = """
        #include <errno.h>
        #include <stdio.h>
        #include <stdlib.h>
        #include <sys/resource.h>
        #include <unistd.h>

        static void set_limit(int resource, rlim_t value) {
            struct rlimit limit = { value, value };
            (void)setrlimit(resource, &limit);
        }

        int main(int argc, char **argv) {
            if (argc < 2) {
                fputs("missing executable\\n", stderr);
                return 126;
            }
            set_limit(RLIMIT_CPU, 4);
            set_limit(RLIMIT_FSIZE, 2 * 1024 * 1024);
            set_limit(RLIMIT_NOFILE, 64);
            set_limit(RLIMIT_NPROC, 64);
        #ifdef RLIMIT_AS
            set_limit(RLIMIT_AS, 256 * 1024 * 1024);
        #endif
            execv(argv[1], &argv[1]);
            perror("execv");
            return 127;
        }
        """

        do {
            try profile.write(to: profileURL, atomically: true, encoding: .utf8)
            try Data().write(to: stdoutURL)
            try Data().write(to: stderrURL)

            if isExecution {
                try runnerSource.write(to: runnerSourceURL, atomically: true, encoding: .utf8)
                let helperCompile = Process()
                helperCompile.executableURL = URL(fileURLWithPath: "/usr/bin/clang")
                helperCompile.arguments = [
                    "-O2",
                    "-Wall",
                    "-Wextra",
                    "-o",
                    runnerURL.path,
                    runnerSourceURL.path
                ]
                helperCompile.currentDirectoryURL = directory
                try helperCompile.run()
                helperCompile.waitUntilExit()
                guard helperCompile.terminationStatus == 0 else {
                    return CodeProcessResult(
                        stdout: "",
                        stderr: "无法创建安全运行启动器。",
                        exitCode: -1,
                        timedOut: false
                    )
                }
            }
        } catch {
            return CodeProcessResult(
                stdout: "",
                stderr: "无法创建沙盒运行文件：\(error.localizedDescription)",
                exitCode: -1,
                timedOut: false
            )
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sandbox-exec")
        if isExecution {
            process.arguments = ["-p", profile, runnerURL.path, executable] + arguments
        } else {
            process.arguments = ["-p", profile, executable] + arguments
        }
        process.currentDirectoryURL = directory
        process.environment = [
            "PATH": "/usr/bin:/bin:/usr/sbin:/sbin",
            "TMPDIR": directory.path,
            "LANG": "zh_CN.UTF-8"
        ]

        let inputPipe = Pipe()
        process.standardInput = inputPipe
        guard let outputHandle = try? FileHandle(forWritingTo: stdoutURL),
              let errorHandle = try? FileHandle(forWritingTo: stderrURL) else {
            return CodeProcessResult(
                stdout: "",
                stderr: "无法创建输出文件。",
                exitCode: -1,
                timedOut: false
            )
        }
        process.standardOutput = outputHandle
        process.standardError = errorHandle

        do {
            try process.run()
        } catch {
            try? outputHandle.close()
            try? errorHandle.close()
            return CodeProcessResult(
                stdout: "",
                stderr: error.localizedDescription,
                exitCode: -1,
                timedOut: false
            )
        }

        if let data = input.data(using: .utf8) {
            inputPipe.fileHandleForWriting.write(data)
        }
        try? inputPipe.fileHandleForWriting.close()

        var timedOut = false
        let timeoutWork = DispatchWorkItem {
            if process.isRunning {
                timedOut = true
                process.terminate()
            }
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: timeoutWork)

        process.waitUntilExit()
        timeoutWork.cancel()
        try? outputHandle.close()
        try? errorHandle.close()

        return CodeProcessResult(
            stdout: limitedString(at: stdoutURL),
            stderr: limitedString(at: stderrURL),
            exitCode: process.terminationStatus,
            timedOut: timedOut
        )
    }

    private static func limitedString(at url: URL, limit: Int = 200_000) -> String {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return "" }
        defer { try? handle.close() }
        let data = (try? handle.read(upToCount: limit)) ?? Data()
        return String(data: data, encoding: .utf8) ?? ""
    }

    private static func normalized(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\r\n", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func failure(_ message: String) -> CodeRunResult {
        CodeRunResult(
            succeeded: false,
            passed: false,
            stdout: "",
            stderr: "",
            exitCode: -1,
            timedOut: false,
            message: message
        )
    }

    private struct CodeProcessResult {
        let stdout: String
        let stderr: String
        let exitCode: Int32
        let timedOut: Bool
    }
    #endif
}


extension CodeRunResult {
    static func remoteFailure(_ message: String) -> CodeRunResult {
        CodeRunResult(
            succeeded: false,
            passed: false,
            stdout: "",
            stderr: "",
            exitCode: -1,
            timedOut: false,
            message: message
        )
    }

    static var remoteUnavailable: CodeRunResult {
        remoteFailure("Mac companion 不可用。请确认 Mac 上的 App 正在运行并连接同一局域网。")
    }
}
