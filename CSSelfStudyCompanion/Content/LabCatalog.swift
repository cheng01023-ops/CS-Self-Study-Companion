import Foundation

struct LearningLab: Identifiable {
    let id: String
    let title: String
    let summary: String
    let icon: String
    let themeHex: String
}

enum LabCatalog {
    static let labs: [LearningLab] = [
        LearningLab(id: "bits", title: "二进制与位运算", summary: "切换 8 个二进制位，观察十进制、十六进制和权限标志。", icon: "number.square.fill", themeHex: "4F7CFF"),
        LearningLab(id: "memory", title: "内存布局", summary: "点击栈、堆、全局数据和代码段，理解对象生命周期。", icon: "memorychip.fill", themeHex: "16A085"),
        LearningLab(id: "tcp", title: "TCP 三次握手", summary: "一步一步发送 SYN、SYN-ACK、ACK，观察连接建立过程。", icon: "arrow.left.arrow.right.circle.fill", themeHex: "2D98DA"),
        LearningLab(id: "hash", title: "哈希碰撞", summary: "向少量桶中加入键，观察碰撞、链地址法和负载因子。", icon: "square.grid.3x3.fill", themeHex: "D35400"),
        LearningLab(id: "logic", title: "逻辑真值表", summary: "切换命题真假，观察与、或、非、蕴含和等价的结果。", icon: "checkmark.diamond.fill", themeHex: "5E5CE6"),
        LearningLab(id: "automata", title: "自动机状态机", summary: "一步一步输入 0/1，观察 DFA 状态转移和接受结果。", icon: "arrow.triangle.branch", themeHex: "AF52DE"),
        LearningLab(id: "probability", title: "概率实验", summary: "切换骰子数量并重复模拟，比较经验频率和理论概率。", icon: "chart.xyaxis.line", themeHex: "FF9F0A"),
        LearningLab(id: "growth", title: "复杂度增长", summary: "调整输入规模，比较 O(1)、O(log n)、O(n)、O(n log n) 和 O(n²)。", icon: "chart.line.uptrend.xyaxis", themeHex: "FF375F")
    ]
}

struct TutorialLabSignal: Identifiable, Hashable {
    let id: String
    let label: String
    let marker: String
    let required: Bool

    init(_ label: String, marker: String = "", required: Bool = true) {
        self.id = label
        self.label = label
        self.marker = marker
        self.required = required
    }
}

struct TutorialLabCheckpoint: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let successCriterion: String
}

struct TutorialLabBlueprint: Identifiable {
    let id: String
    let tutorialID: String
    let title: String
    let objective: String
    let scenario: String
    let prerequisites: [String]
    let safetyNote: String
    let terminalCommand: String
    let codeLanguage: String
    let code: String
    let standardInput: String
    let expectedSignals: [TutorialLabSignal]
    let failureDrill: String
    let checkpoints: [TutorialLabCheckpoint]
    let estimatedMinutes: Int

    var isRunnableInApp: Bool {
        !code.isEmpty && ["c", "swift"].contains(codeLanguage.lowercased())
    }

    var evidenceTargetID: String {
        TutorialLabCatalog.evidenceTargetID(tutorialID)
    }
}

struct TutorialLabEvidence: Codable, Equatable {
    var prediction = ""
    var preparationConfirmed = false
    var rollbackPlan = ""
    var commandUsed = ""
    var observedOutput = ""
    var exitCode = ""
    var anomaly = ""
    var rootCause = ""
    var insight = ""

    static let empty = TutorialLabEvidence()
}

enum TutorialLabEvidenceCodec {
    private static let prefix = "CS-LAB-EVIDENCE-V1\n"

    static func encode(_ evidence: TutorialLabEvidence) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(evidence),
              let json = String(data: data, encoding: .utf8) else {
            return prefix
        }
        return prefix + json
    }

    static func decode(_ text: String) -> TutorialLabEvidence {
        guard text.hasPrefix(prefix) else { return .empty }
        let json = String(text.dropFirst(prefix.count))
        guard let data = json.data(using: .utf8),
              let evidence = try? JSONDecoder().decode(TutorialLabEvidence.self, from: data) else {
            return .empty
        }
        return evidence
    }
}

enum TutorialLabStage: Int, CaseIterable, Identifiable {
    case brief
    case predict
    case prepare
    case run
    case verify
    case reflect

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .brief: "目标"
        case .predict: "预测"
        case .prepare: "准备"
        case .run: "执行"
        case .verify: "验证"
        case .reflect: "复盘"
        }
    }

    var subtitle: String {
        switch self {
        case .brief: "明确实验目标和验收边界"
        case .predict: "先写预测，避免事后解释"
        case .prepare: "隔离环境并确认回滚方式"
        case .run: "执行最小实验并保存原始证据"
        case .verify: "逐条核对结果与失败路径"
        case .reflect: "解释原因、修复并形成复习卡"
        }
    }

    var icon: String {
        switch self {
        case .brief: "scope"
        case .predict: "questionmark.bubble.fill"
        case .prepare: "checklist"
        case .run: "play.rectangle.fill"
        case .verify: "checkmark.shield.fill"
        case .reflect: "arrow.triangle.2.circlepath.circle.fill"
        }
    }
}

enum TutorialLabCatalog {
    static func blueprint(
        tutorialID: String,
        title: String,
        summary: String,
        codeLanguage: String,
        code: String
    ) -> TutorialLabBlueprint {
        let seed = seed(for: tutorialID) ?? fallback(
            title: title,
            summary: summary,
            codeLanguage: codeLanguage,
            code: code
        )

        return TutorialLabBlueprint(
            id: "tutorial-lab-\(tutorialID)",
            tutorialID: tutorialID,
            title: title,
            objective: seed.objective,
            scenario: seed.scenario,
            prerequisites: seed.prerequisites,
            safetyNote: seed.safetyNote,
            terminalCommand: seed.terminalCommand,
            codeLanguage: seed.codeLanguage ?? codeLanguage,
            code: seed.codeOverride ?? code,
            standardInput: seed.standardInput,
            expectedSignals: seed.expectedSignals,
            failureDrill: seed.failureDrill,
            checkpoints: seed.checkpoints.enumerated().map { index, checkpoint in
                TutorialLabCheckpoint(
                    id: "check-\(index + 1)",
                    title: checkpoint.0,
                    detail: checkpoint.1,
                    successCriterion: checkpoint.2
                )
            },
            estimatedMinutes: seed.estimatedMinutes
        )
    }

    static func markdownSection(
        tutorialID: String,
        title: String,
        summary: String,
        codeLanguage: String,
        code: String
    ) -> String {
        let lab = blueprint(
            tutorialID: tutorialID,
            title: title,
            summary: summary,
            codeLanguage: codeLanguage,
            code: code
        )

        let prerequisites = lab.prerequisites.map { "- \($0)" }.joined(separator: "\n")
        let signals = lab.expectedSignals.map {
            "- \($0.required ? "必验" : "观察")：\($0.label)\($0.marker.isEmpty ? "" : "；可检索标记：`\($0.marker)`")"
        }.joined(separator: "\n")
        let checks = lab.checkpoints.enumerated().map {
            "\($0.offset + 1). **\($0.element.title)**：\($0.element.successCriterion)"
        }.joined(separator: "\n")
        let command = lab.terminalCommand.isEmpty ? "本实验直接在 App 的代码工作台运行最小程序。" : "```bash\n\(lab.terminalCommand)\n```"
        let codeBlock = lab.code.isEmpty ? "" : "\n```\(lab.codeLanguage)\n\(lab.code)\n```\n"

        return #"""
# 可验证实验课：\#(lab.title)

这不是普通阅读任务，而是一节必须留下证据的实验课。核心目标：\#(lab.objective)

## 实验场景

\#(lab.scenario)

预计需要 \#(lab.estimatedMinutes) 分钟。请按照“目标 → 预测 → 准备 → 执行 → 验证 → 复盘”六步完成，不要直接翻到答案。

## 开始前检查

\#(prerequisites)

安全边界：\#(lab.safetyNote)

## 第一步：先写下预测

执行前回答：你认为正常输入会产生什么结果？退出码应该是多少？哪个条件最容易触发失败？预测必须具体到输出、文件状态、进程状态或权限变化。实验结束后，用原始证据确认或推翻预测。

## 第二步：准备最小环境

选择一个临时目录或隔离环境，记录系统版本、工具版本、当前目录和回滚命令。不要使用生产数据，不要把“重新安装”作为第一反应。先保存现场，再改变环境。

\#(command)
\#(codeBlock)

## 第三步：执行并保存证据

至少记录：实际命令或输入、标准输出、错误输出、退出码、关键文件状态。输出不要只写“成功”。如果结果不同，先保留完整错误和版本信息，再做最小复现。

## 第四步：验证结果

\#(signals)

验收清单：

\#(checks)

## 第五步：故意制造一次失败

\#(lab.failureDrill)

错误实验必须在可恢复环境中进行。定位时先读第一条错误，再检查类型、路径、权限、输入和资源边界。修复后重新运行正常路径，确认没有引入回归。

## 第六步：复盘并进入复习系统

用“症状 → 证据 → 根因 → 修复 → 预防”写一条复盘。若实验未通过，把它加入复习系统；若已通过，也要写清一个仍然不确定的边界。完成标准是：另一位学习者只读你的证据记录，也能复现结果并判断是否通过。
"""#
    }

    static func evidenceTargetID(_ tutorialID: String) -> String {
        "lab:\(tutorialID):evidence"
    }

    static func stageProgressID(_ tutorialID: String, stage: Int) -> String {
        "lab:\(tutorialID):stage:\(stage)"
    }

    static func checkpointProgressID(_ tutorialID: String, checkpointID: String) -> String {
        "lab:\(tutorialID):checkpoint:\(checkpointID)"
    }

    private struct Seed {
        let objective: String
        let scenario: String
        let prerequisites: [String]
        let safetyNote: String
        let terminalCommand: String
        let codeLanguage: String?
        let codeOverride: String?
        let standardInput: String
        let expectedSignals: [TutorialLabSignal]
        let failureDrill: String
        let checkpoints: [(String, String, String)]
        let estimatedMinutes: Int

        init(
            objective: String,
            scenario: String,
            prerequisites: [String] = [
                "能打开终端或 App 的代码工作台，并知道当前工作目录。",
                "准备一个可删除的临时目录，不要使用唯一副本。",
                "能够保存原始命令、输出和退出码。"
            ],
            safetyNote: String = "只修改临时目录中的文件；涉及权限、进程或网络时先确认可以回滚。",
            terminalCommand: String = "",
            codeLanguage: String? = nil,
            codeOverride: String? = nil,
            standardInput: String = "",
            expectedSignals: [TutorialLabSignal],
            failureDrill: String,
            checkpoints: [(String, String, String)],
            estimatedMinutes: Int = 35
        ) {
            self.objective = objective
            self.scenario = scenario
            self.prerequisites = prerequisites
            self.safetyNote = safetyNote
            self.terminalCommand = terminalCommand
            self.codeLanguage = codeLanguage
            self.codeOverride = codeOverride
            self.standardInput = standardInput
            self.expectedSignals = expectedSignals
            self.failureDrill = failureDrill
            self.checkpoints = checkpoints
            self.estimatedMinutes = estimatedMinutes
        }
    }

    private static func seed(for tutorialID: String) -> Seed? {
        switch tutorialID {
        case "tutorial-mac-terminal":
            return Seed(
                objective: "从终端创建目录、编译并运行一个 C 程序，再通过非零退出码定位一次路径错误。",
                scenario: "模拟第一次建立开发目录：先确认位置，再编译 hello.c，最后运行程序。",
                terminalCommand: "mkdir -p /tmp/cs-lab-terminal && cd /tmp/cs-lab-terminal\nprintf '#include <stdio.h>\\nint main(void) { puts(\"hello, cs\"); return 0; }\\n' > hello.c\nclang -Wall -Wextra -g -o hello hello.c\n./hello\necho $?",
                codeLanguage: "c",
                codeOverride: "#include <stdio.h>\n\nint main(void) {\n    puts(\"hello, cs\");\n    return 0;\n}\n",
                expectedSignals: [
                    TutorialLabSignal("程序输出 hello, cs", marker: "hello, cs"),
                    TutorialLabSignal("编译退出码为 0", marker: "0"),
                    TutorialLabSignal("编译过程没有 warning/error", marker: "error", required: false),
                    TutorialLabSignal("已生成可执行文件 hello", marker: "hello")
                ],
                failureDrill: "执行 `cd /tmp/cs-lab-terminal/不存在`，记录 Shell 的第一条错误和 `echo $?` 的非零退出码，然后回到临时目录。",
                checkpoints: [
                    ("位置检查", "先执行 pwd，确认所有操作都在临时目录。", "能看到绝对路径且不包含个人重要目录。"),
                    ("编译成功", "使用 clang 加警告选项编译程序。", "生成可执行文件且退出码为 0。"),
                    ("运行证据", "执行程序并保存 stdout 与退出码。", "输出 hello, cs，退出码为 0。"),
                    ("错误复现", "进入不存在的目录并检查退出码。", "错误可复现且没有修改系统状态。")
                ]
            )

        case "tutorial-computer-basics":
            return Seed(
                objective: "用位运算构造权限标志，并验证二进制、十六进制、整数和指针的实际大小。",
                scenario: "把一个字节当成 8 个开关，分别打开 READ 与 EXECUTE，观察结果。",
                expectedSignals: [
                    TutorialLabSignal("flags 的十进制值为 5", marker: "flags = 5"),
                    TutorialLabSignal("二进制位模式为 00000101", marker: "00000101"),
                    TutorialLabSignal("读权限检查结果为 yes", marker: "read? yes"),
                    TutorialLabSignal("输出了 int 与指针大小", marker: "int:")
                ],
                failureDrill: "把 `1u << 0` 改成 `1u << 8`，观察 uint8_t 截断后的结果，再解释为什么位编号不能超过 7。",
                checkpoints: [
                    ("预测位模式", "先手算 READ|EXECUTE 的十进制、二进制和十六进制。", "预测值为 5、00000101、0x05。"),
                    ("运行观察", "编译运行代码并保存完整输出。", "输出中的值与自己手算一致。"),
                    ("解释位权", "说明 1u << n 的含义和 uint8_t 的有效范围。", "能解释位权、截断和 0..255 的范围。"),
                    ("制造边界错误", "把位移改为 8 并比较结果。", "记录异常行为并说明根因。")
                ]
            )

        case "tutorial-c-foundation":
            return Seed(
                objective: "用结构体数组查找学生、打印结果并写入 scores.txt，然后验证文件内容和资源生命周期。",
                scenario: "把“数据、控制、组合、地址、持久化”串成一次可检查的 C 程序。",
                expectedSignals: [
                    TutorialLabSignal("找到 Grace", marker: "Grace"),
                    TutorialLabSignal("分数为 92", marker: "92"),
                    TutorialLabSignal("程序退出码为 0", marker: "0"),
                    TutorialLabSignal("生成 scores.txt", marker: "scores.txt")
                ],
                failureDrill: "把查找姓名改成不存在的 `missing`，观察程序分支；同时把文件路径改成不可写目录，检查 fopen 失败是否被处理。",
                checkpoints: [
                    ("正常路径", "运行原始程序并保存输出。", "输出 Grace 的分数为 92，退出码为 0。"),
                    ("文件验证", "执行 cat scores.txt 并检查三行记录。", "文件存在且包含 Ada、Linus、Grace。"),
                    ("错误路径", "触发查找失败或 fopen 失败。", "程序返回可识别结果，不崩溃、不越界。"),
                    ("资源复盘", "指出 fopen、malloc/数组和 fclose 的所有权。", "能说明谁申请、谁使用、谁释放。")
                ]
            )

        case "tutorial-linux-l0":
            return Seed(
                objective: "确认 Ubuntu LTS 版本、内核和 SSH 身份，并完成一次安全的系统更新准备。",
                scenario: "在 UTM、Docker 或云服务器中的一台 Ubuntu 上完成首次登录检查。",
                prerequisites: [
                    "已经有一台 Ubuntu LTS 虚拟机、容器或云服务器。",
                    "知道服务器地址、用户名和 SSH 私钥位置。",
                    "云安全组只开放必要的 SSH 端口。"
                ],
                safetyNote: "先确认连接的是练习机器；不要上传私钥，不要开放全部端口，不要在生产服务器上做破坏性实验。",
                terminalCommand: "ssh ubuntu@服务器地址\n# 登录后逐条执行\ncat /etc/os-release\nuname -a\nwhoami\nip addr\ndf -h\nsudo apt update",
                expectedSignals: [
                    TutorialLabSignal("系统标识为 Ubuntu", marker: "ubuntu"),
                    TutorialLabSignal("能看到 Linux 内核版本", marker: "Linux"),
                    TutorialLabSignal("能识别当前用户", marker: "ubuntu"),
                    TutorialLabSignal("apt update 成功", marker: "Hit", required: false)
                ],
                failureDrill: "使用错误主机名并加 `-o ConnectTimeout=3`，记录 DNS 或连接失败的区别；不要反复尝试真实生产地址。",
                checkpoints: [
                    ("环境身份", "记录系统版本、内核和用户名。", "三者与预期练习机器一致。"),
                    ("网络证据", "保存 IP 地址和 SSH 登录结果。", "能说明客户端与服务器之间的连接路径。"),
                    ("包管理准备", "执行 apt update 并保存最后几行。", "命令正常结束且没有忽略权限错误。"),
                    ("失败边界", "复现一次无效主机连接。", "能区分 DNS、网络和认证错误。")
                ]
            )

        case "tutorial-linux-l1":
            return Seed(
                objective: "在临时目录中完成文件创建、复制、移动、删除和权限修改，并用 stat 证明权限变化。",
                scenario: "模拟整理项目目录：准备输入文件，设置脚本可执行位，再撤销权限。",
                prerequisites: [
                    "已登录 Ubuntu 练习环境。",
                    "熟悉 ls、cd、mkdir 和 echo。",
                    "知道 chmod 数字权限的含义。"
                ],
                terminalCommand: "rm -rf /tmp/cs-l1 && mkdir -p /tmp/cs-l1/input /tmp/cs-l1/output\ncd /tmp/cs-l1\nprintf 'alpha\\nbeta\\n' > input/data.txt\ncp input/data.txt output/data.txt\nchmod 644 output/data.txt\nstat -c '%a %n' output/data.txt\nchmod 755 output\nstat -c '%a %n' output",
                expectedSignals: [
                    TutorialLabSignal("文件权限为 644", marker: "644"),
                    TutorialLabSignal("目录权限为 755", marker: "755"),
                    TutorialLabSignal("输出目录存在", marker: "output"),
                    TutorialLabSignal("文件内容为两行", marker: "alpha")
                ],
                failureDrill: "创建只读目录后尝试写入文件，记录 Permission denied；不要把 chmod 777 当作修复。",
                checkpoints: [
                    ("目录结构", "创建 input 与 output 两个目录。", "目录树符合预期且位于 /tmp。"),
                    ("复制与验证", "复制文件并比较内容。", "源文件和目标文件内容一致。"),
                    ("权限验证", "使用 stat 或 ls -l 检查权限。", "文件为 644，目录为 755。"),
                    ("权限失败", "在只读目录中写入并解释错误。", "不通过扩大权限掩盖错误。")
                ]
            )

        case "tutorial-linux-l2":
            return Seed(
                objective: "用 grep、awk、sed、find 和管道从日志中提取一次可复核的统计结果。",
                scenario: "准备一小组混合日志，统计 ERROR 数量并提取出现次数最多的接口。",
                prerequisites: [
                    "已登录 Linux 练习环境。",
                    "能读懂基本重定向 > 和管道 |。",
                    "知道 grep 失败时会返回非零退出码。"
                ],
                terminalCommand: "rm -rf /tmp/cs-l2 && mkdir -p /tmp/cs-l2 && cd /tmp/cs-l2\ncat > app.log <<'EOF'\nINFO /health 200\nERROR /login 500\nWARN /login 401\nERROR /login 500\nINFO /home 200\nEOF\ngrep -c 'ERROR' app.log\nawk '$1==\"ERROR\" {print $2}' app.log | sort | uniq -c | sort -nr\nsed -n '2,4p' app.log\nfind . -maxdepth 1 -type f -name '*.log' -print",
                expectedSignals: [
                    TutorialLabSignal("ERROR 数量为 2", marker: "2"),
                    TutorialLabSignal("定位到 /login", marker: "/login"),
                    TutorialLabSignal("输出指定日志区间", marker: "ERROR /login"),
                    TutorialLabSignal("find 找到 app.log", marker: "app.log")
                ],
                failureDrill: "删除日志后重跑管道，检查 grep 与管道的退出码；在脚本中加入 `set -o pipefail` 观察差异。",
                checkpoints: [
                    ("准备数据", "创建至少包含 INFO、WARN、ERROR 的日志。", "日志内容可查看且没有覆盖原文件。"),
                    ("提取统计", "用 grep 和 awk 生成结果。", "ERROR 数量为 2。"),
                    ("管道解释", "说明每一段命令的输入和输出。", "能从左到右解释数据流。"),
                    ("错误退出", "让 grep 找不到匹配并检查退出码。", "能解释管道默认退出状态。")
                ]
            )

        case "tutorial-linux-l3":
            return Seed(
                objective: "用 ps、systemctl、journalctl、df、ss 和 cron 建立一台服务的可观测性快照。",
                scenario: "检查练习机的进程、服务、日志、磁盘、监听端口和计划任务。",
                prerequisites: [
                    "已登录 Linux 练习环境。",
                    "知道 systemd 可能不可用于 Docker 容器。",
                    "不需要停止或删除真实服务。"
                ],
                safetyNote: "只读检查优先；涉及 systemctl restart、kill 或 cron 时必须确认对象是练习服务。",
                terminalCommand: "date\nps -eo pid,ppid,stat,comm | head\nsystemctl --type=service --state=running | head\njournalctl -n 20 --no-pager\ndf -h\nss -lntup\ncrontab -l 2>&1 || true",
                expectedSignals: [
                    TutorialLabSignal("保存了进程快照", marker: "PID"),
                    TutorialLabSignal("保存了日志时间", marker: "20"),
                    TutorialLabSignal("记录磁盘使用率", marker: "%"),
                    TutorialLabSignal("记录监听端口", marker: "LISTEN", required: false)
                ],
                failureDrill: "在容器中执行 `systemctl status`，记录 init 系统不可用的错误；换到虚拟机解释为什么观察对象不同。",
                checkpoints: [
                    ("进程证据", "找到至少一个进程及其 PPID。", "能解释父子进程关系。"),
                    ("服务与日志", "关联一个 systemd 服务与 journalctl 日志。", "记录服务名和日志时间。"),
                    ("资源证据", "记录磁盘和监听端口。", "能指出一个容量或暴露面风险。"),
                    ("容器边界", "比较容器与虚拟机的 init 行为。", "能解释为什么同一命令结果不同。")
                ]
            )

        case "tutorial-linux-l4":
            return Seed(
                objective: "编写一个调用 POSIX 文件接口的 C 程序，验证返回值、错误码和文件描述符生命周期。",
                scenario: "通过 open/read/write/close 完成一次最小文件 I/O，并为失败路径预留清理。",
                prerequisites: [
                    "Linux 练习环境已安装 build-essential。",
                    "能在终端运行 gcc 或 clang。",
                    "知道文件描述符是进程内的小整数。"
                ],
                terminalCommand: "cat > /tmp/cs-l4.c <<'EOF'\n#include <fcntl.h>\n#include <stdio.h>\n#include <unistd.h>\nint main(void) {\n    const char *path = \"/tmp/cs-l4.txt\";\n    int fd = open(path, O_CREAT | O_WRONLY | O_TRUNC, 0644);\n    if (fd < 0) { perror(\"open\"); return 1; }\n    const char text[] = \"POSIX io\\n\";\n    ssize_t n = write(fd, text, sizeof(text) - 1);\n    if (n < 0) { perror(\"write\"); close(fd); return 1; }\n    close(fd);\n    puts(\"wrote /tmp/cs-l4.txt\");\n    return 0;\n}\nEOF\ngcc -Wall -Wextra -g /tmp/cs-l4.c -o /tmp/cs-l4\n/tmp/cs-l4\ncat /tmp/cs-l4.txt",
                codeLanguage: "c",
                codeOverride: "#include <fcntl.h>\n#include <stdio.h>\n#include <unistd.h>\n\nint main(void) {\n    const char *path = \"/tmp/cs-l4.txt\";\n    int fd = open(path, O_CREAT | O_WRONLY | O_TRUNC, 0644);\n    if (fd < 0) { perror(\"open\"); return 1; }\n    const char text[] = \"POSIX io\\n\";\n    ssize_t written = write(fd, text, sizeof(text) - 1);\n    if (written < 0) { perror(\"write\"); close(fd); return 1; }\n    close(fd);\n    puts(\"wrote /tmp/cs-l4.txt\");\n    return 0;\n}\n",
                expectedSignals: [
                    TutorialLabSignal("程序输出写入路径", marker: "/tmp/cs-l4.txt"),
                    TutorialLabSignal("文件内容可读", marker: "POSIX io"),
                    TutorialLabSignal("程序退出码为 0", marker: "0"),
                    TutorialLabSignal("open 或 write 失败会返回并清理", marker: "perror", required: false)
                ],
                failureDrill: "把路径改成不可写目录或只读文件，记录 errno/perror；修复时确保 `open` 失败后不会继续 `write`。",
                checkpoints: [
                    ("返回值检查", "检查 open 和 write 的每个返回值。", "失败路径有错误输出和非零退出码。"),
                    ("正常 I/O", "运行后读回文件内容。", "内容为 POSIX io。"),
                    ("生命周期", "说明 fd 从 open 到 close 的所有权。", "每个成功打开的 fd 都被关闭。"),
                    ("故障注入", "制造 open 或 write 失败。", "错误可见且没有继续使用无效 fd。")
                ]
            )

        case "tutorial-linux-l5":
            return Seed(
                objective: "观察一次 HTTP 请求经过 DNS、TCP、HTTP 和 Nginx 的路径，并保留状态码与响应头。",
                scenario: "对练习服务执行 curl -v，记录 DNS、连接、TLS/HTTP 头和响应体。",
                prerequisites: [
                    "有一台可访问的 Ubuntu 练习机或本地服务。",
                    "服务端口和域名由你控制。",
                    "知道不要对陌生主机做扫描或压力测试。"
                ],
                safetyNote: "只对自有或明确授权的服务发起请求；不要扫描公网地址，不要使用高并发压测。",
                terminalCommand: "curl -v --connect-timeout 5 http://127.0.0.1/\nss -lntp | grep ':80\\|:443' || true\ncurl -I --connect-timeout 5 http://127.0.0.1/ 2>&1 || true\n# 若使用 Nginx，查看配置与日志\n# nginx -T\n# journalctl -u nginx -n 30 --no-pager",
                expectedSignals: [
                    TutorialLabSignal("能看到 HTTP 状态码", marker: "HTTP/"),
                    TutorialLabSignal("能看到响应头", marker: "Content-", required: false),
                    TutorialLabSignal("能区分连接阶段", marker: "Connected to", required: false),
                    TutorialLabSignal("失败时返回非零退出码", marker: "curl:", required: false)
                ],
                failureDrill: "请求一个未监听端口，记录 connection refused；再请求不存在路径，比较连接失败与 HTTP 404 的层次差异。",
                checkpoints: [
                    ("请求证据", "保存 curl -v 的请求行、状态码和响应头。", "能定位 DNS、TCP、HTTP 三个阶段。"),
                    ("代理证据", "如果使用 Nginx，记录 upstream 或 access log。", "能指出反向代理转发的目标。"),
                    ("错误分层", "分别制造连接失败和 404。", "能解释两类错误不在同一层。"),
                    ("安全边界", "只使用授权目标并限制超时。", "没有扫描、压测或访问生产数据。")
                ]
            )

        case "tutorial-linux-l6":
            return Seed(
                objective: "用 strace 和基础性能工具观察一个程序的系统调用、时间消耗和资源变化。",
                scenario: "对一个短命 C 或 Shell 程序做跟踪，找出它打开的文件、返回值和退出状态。",
                prerequisites: [
                    "Linux 练习环境安装 strace、perf 或基础 procps 工具。",
                    "知道跟踪工具本身也会带来开销。",
                    "只跟踪自己启动的练习进程。"
                ],
                safetyNote: "不要跟踪他人的敏感进程；perf 和内核接口可能受权限限制，遇到限制时记录边界而不是强行绕过。",
                terminalCommand: "cat > /tmp/cs-l6.c <<'EOF'\n#include <stdio.h>\nint main(void) { FILE *f = fopen(\"/etc/hostname\", \"r\"); if (!f) return 1; char b[64]; fgets(b, sizeof b, f); fclose(f); puts(\"probe complete\"); return 0; }\nEOF\ngcc -Wall -Wextra /tmp/cs-l6.c -o /tmp/cs-l6\nstrace -f -e trace=openat,read,write,close /tmp/cs-l6 2>&1 | tail -30\ntime /tmp/cs-l6",
                codeLanguage: "c",
                codeOverride: "#include <stdio.h>\n\nint main(void) {\n    FILE *file = fopen(\"/etc/hostname\", \"r\");\n    if (file == NULL) return 1;\n    char buffer[64];\n    if (fgets(buffer, sizeof(buffer), file) == NULL) {\n        fclose(file);\n        return 2;\n    }\n    fclose(file);\n    puts(\"probe complete\");\n    return 0;\n}\n",
                expectedSignals: [
                    TutorialLabSignal("程序输出 probe complete", marker: "probe complete"),
                    TutorialLabSignal("strace 显示 openat", marker: "openat"),
                    TutorialLabSignal("strace 显示 close", marker: "close"),
                    TutorialLabSignal("time 记录真实耗时", marker: "real")
                ],
                failureDrill: "把文件改成不存在的路径，观察 fopen 返回 NULL、程序退出码变化和 strace 的 ENOENT。",
                checkpoints: [
                    ("正常跟踪", "保存 openat、read、write 或 close 系统调用。", "能把系统调用与源码行为对应起来。"),
                    ("错误跟踪", "制造 ENOENT 并检查返回值。", "错误码、程序返回值和输出一致。"),
                    ("性能基线", "记录一次 time 结果。", "知道该数字不是稳定性基准。"),
                    ("工具边界", "说明 strace 带来的延迟和权限限制。", "不把跟踪结果误当成生产性能。")
                ]
            )

        case "tutorial-linux-l7":
            return Seed(
                objective: "进入 Ubuntu 容器，观察 PID、挂载点和 cgroup 限制，理解隔离与共享内核的边界。",
                scenario: "运行一个资源受限的容器，在容器内外比较进程视图、根文件系统和内存限制。",
                prerequisites: [
                    "Docker 已安装且能运行 hello-world。",
                    "已明确当前不是在运行高风险工作负载。",
                    "知道容器共享宿主机内核。"
                ],
                safetyNote: "不要使用 --privileged，不要挂载宿主机根目录；实验容器使用 --rm 并及时清理。",
                terminalCommand: "docker run --rm --memory=128m --cpus=0.5 ubuntu:24.04 bash -lc 'echo PID=$$; cat /proc/1/cgroup; findmnt -T /; free -h; hostname'\ndocker ps -a\ndocker info | grep -i -E 'runtime|rootless|storage' || true",
                expectedSignals: [
                    TutorialLabSignal("记录容器 PID", marker: "PID="),
                    TutorialLabSignal("记录 cgroup 层级", marker: "cgroup"),
                    TutorialLabSignal("记录容器主机名", marker: "hostname", required: false),
                    TutorialLabSignal("Docker 显示清理状态", marker: "ubuntu:24.04", required: false)
                ],
                failureDrill: "尝试在容器内修改内核模块或启动 systemd，记录权限或 init 系统错误，并解释它为什么不等同于虚拟机。",
                checkpoints: [
                    ("PID 隔离", "比较容器内 PID 1 与宿主机进程列表。", "能说明命名空间改变的是视图。"),
                    ("资源限制", "保存 --memory 和 cgroup 证据。", "能解释 cgroup 如何限制资源。"),
                    ("文件系统", "记录 findmnt 或根目录差异。", "能区分镜像层、可写层和宿主机挂载。"),
                    ("内核共享", "复现一次内核权限边界。", "能解释容器不是轻量虚拟机的唯一原因。")
                ]
            )

        case "tutorial-linux-l8":
            return Seed(
                objective: "检查 SSH 密钥权限、防火墙状态和强制访问控制状态，建立服务器第一道安全边界。",
                scenario: "在自有练习服务器上只读检查 sshd 配置、UFW 和 AppArmor/SELinux。",
                prerequisites: [
                    "有一台自有或明确授权的练习服务器。",
                    "不要把私钥粘贴到命令行或聊天工具。",
                    "不要直接修改远程防火墙导致自己失联。"
                ],
                safetyNote: "这是只读安全审计。修改防火墙或 SSH 配置前必须确认备用登录方式，并保留回滚窗口。",
                terminalCommand: "ls -l ~/.ssh\nssh -o BatchMode=yes -o ConnectTimeout=5 -T git@github.com 2>&1 | head\nsudo sshd -T 2>/dev/null | grep -E 'permitrootlogin|passwordauthentication|pubkeyauthentication' || true\nsudo ufw status verbose 2>/dev/null || true\nsudo aa-status 2>/dev/null | head || true\nsudo sestatus 2>/dev/null | head || true",
                expectedSignals: [
                    TutorialLabSignal("未泄露私钥内容", marker: "id_ed25519", required: false),
                    TutorialLabSignal("记录 SSH 认证策略", marker: "permitrootlogin", required: false),
                    TutorialLabSignal("记录防火墙状态", marker: "Status", required: false),
                    TutorialLabSignal("记录 MAC 状态", marker: "AppArmor", required: false)
                ],
                failureDrill: "在实验虚拟机中把密码登录临时设为禁止前，先确认公钥登录可用；记录如果配置错误，控制台如何恢复。",
                checkpoints: [
                    ("密钥权限", "检查私钥是否仅所有者可读写。", "私钥权限为 600 且未输出内容。"),
                    ("SSH 策略", "只读检查 root 和密码登录配置。", "能指出一个需要加固或确认的项。"),
                    ("网络边界", "记录 UFW 或安全组开放端口。", "端口与真实服务需求一致。"),
                    ("MAC 边界", "确认 AppArmor 或 SELinux 状态。", "知道它保护的是内核资源访问而非只保护网络。")
                ]
            )

        case "tutorial-dsa":
            return Seed(
                objective: "实现并验证单链表反转，使用不变量解释指针操作，并覆盖空链表、单节点和一般链表。",
                scenario: "用三个指针重排 next 关系，让每个节点只被处理一次。",
                expectedSignals: [
                    TutorialLabSignal("一般链表输出反转结果", marker: "3 2 1"),
                    TutorialLabSignal("空链表正常处理", marker: "empty", required: false),
                    TutorialLabSignal("程序退出码为 0", marker: "0"),
                    TutorialLabSignal("没有越界访问", marker: "", required: false)
                ],
                failureDrill: "临时删除保存 next 的变量，观察节点丢失或无限循环风险；恢复后再用单节点和空链表验证。",
                checkpoints: [
                    ("手动画链", "在纸上画出三个节点的 before/after 指针关系。", "每次赋值后没有丢失未处理节点。"),
                    ("实现反转", "运行普通链表并比较输出。", "顺序变为 3 2 1。"),
                    ("边界测试", "测试空链表、单节点和两节点。", "没有崩溃、泄漏或无限循环。"),
                    ("复杂度证明", "说明时间 O(n) 与额外空间 O(1)。", "结论与实现一致。")
                ]
            )

        case "tutorial-architecture":
            return Seed(
                objective: "把 C 函数编译成汇编，定位参数寄存器、返回值和栈帧变化，再调整优化等级比较输出。",
                scenario: "用小函数避免编译器过度内联，使用 objdump 观察调用约定。",
                terminalCommand: "cat > /tmp/cs-asm.c <<'EOF'\n__attribute__((noinline)) int add3(int a, int b, int c) { return a + b + c; }\nint main(void) { return add3(1, 2, 3); }\nEOF\nclang -O0 -g -c /tmp/cs-asm.c -o /tmp/cs-asm.o\nobjdump -d /tmp/cs-asm.o | sed -n '/<add3>:/,/^$/p'\nclang -O2 -c /tmp/cs-asm.c -o /tmp/cs-asm-o2.o\nobjdump -d /tmp/cs-asm-o2.o | sed -n '/<add3>:/,/^$/p'",
                codeLanguage: "c",
                codeOverride: "#include <stdio.h>\n\n__attribute__((noinline))\nstatic int add3(int a, int b, int c) {\n    return a + b + c;\n}\n\nint main(void) {\n    int result = add3(1, 2, 3);\n    printf(\"result=%d\\n\", result);\n    return 0;\n}\n",
                expectedSignals: [
                    TutorialLabSignal("程序结果为 6", marker: "result=6"),
                    TutorialLabSignal("汇编中出现参数寄存器", marker: "edi"),
                    TutorialLabSignal("汇编中出现返回寄存器", marker: "eax"),
                    TutorialLabSignal("O0 与 O2 输出不同", marker: "add3")
                ],
                failureDrill: "把函数改成 `static inline` 并提高优化等级，观察符号消失或调用被内联；解释为什么不能只靠汇编片段判断原始逻辑。",
                checkpoints: [
                    ("C 输出", "运行程序确认结果为 6。", "输出 result=6。"),
                    ("调用约定", "在汇编中定位 edi、esi、edx 和 eax。", "能说明参数与返回值寄存器。"),
                    ("栈帧对比", "比较 O0 与 O2 的符号和指令数量。", "能解释优化对可读性的影响。"),
                    ("边界意识", "说明内联和编译器优化可能隐藏调用。", "不会把一条指令当作跨平台承诺。")
                ]
            )

        case "tutorial-os-systems":
            return Seed(
                objective: "运行 POSIX 线程程序，观察共享内存、返回值，并用同步机制修复一次数据竞争。",
                scenario: "多个线程读取或修改同一状态，先观察问题，再使用互斥锁或原子操作验证修复。",
                expectedSignals: [
                    TutorialLabSignal("线程成功创建并 join", marker: "thread"),
                    TutorialLabSignal("输出最终计数或共享状态", marker: "count"),
                    TutorialLabSignal("退出码为 0", marker: "0"),
                    TutorialLabSignal("同步版本结果稳定", marker: "", required: false)
                ],
                failureDrill: "去掉锁并反复运行，观察计数漂移或结果不稳定；记录编译器、迭代次数和平台，而不是声称一次失败就证明竞态。",
                checkpoints: [
                    ("创建与回收", "检查 pthread_create 和 pthread_join 返回值。", "没有线程资源泄漏。"),
                    ("共享状态", "明确哪些变量被多个线程访问。", "每个共享写都有同步或所有权规则。"),
                    ("竞态实验", "反复运行无锁版本并记录变化。", "能区分概率性问题和确定性错误。"),
                    ("修复验证", "加锁或使用原子以后重复运行。", "结果稳定且性能取舍可解释。")
                ]
            )

        case "tutorial-networking":
            return Seed(
                objective: "运行一个短命 Socket 程序，验证连接建立、收发数据和关闭流程，再映射到 HTTP 请求。",
                scenario: "先观察客户端连接结果，再解释 accept、read/write 和 HTTP 响应之间的数据流。",
                prerequisites: [
                    "知道不要对公网陌生主机扫描或压测。",
                    "只在本机或自有局域网地址运行服务器。",
                    "准备好终端、curl 和端口检查工具。"
                ],
                safetyNote: "服务器只监听 127.0.0.1，不上传敏感数据，不保持长期开放端口。",
                terminalCommand: "ss -lntp | head\ncurl -v --connect-timeout 3 http://127.0.0.1:18080/ 2>&1 || true\n# 如果使用了 C 服务器，请用另一个终端运行并用 Ctrl+C 结束\n# nc -vz 127.0.0.1 18080",
                codeLanguage: "c",
                codeOverride: "#include <arpa/inet.h>\n#include <stdio.h>\n#include <string.h>\n#include <sys/socket.h>\n#include <unistd.h>\n\nint main(void) {\n    int fd = socket(AF_INET, SOCK_STREAM, 0);\n    if (fd < 0) { perror(\"socket\"); return 1; }\n    int yes = 1;\n    setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes));\n    struct sockaddr_in address = {0};\n    address.sin_family = AF_INET;\n    address.sin_addr.s_addr = htonl(INADDR_LOOPBACK);\n    address.sin_port = 0;\n    if (bind(fd, (struct sockaddr *)&address, sizeof(address)) < 0) { perror(\"bind\"); close(fd); return 1; }\n    if (listen(fd, 1) < 0) { perror(\"listen\"); close(fd); return 1; }\n    socklen_t length = sizeof(address);\n    if (getsockname(fd, (struct sockaddr *)&address, &length) < 0) { perror(\"getsockname\"); close(fd); return 1; }\n    printf(\"TCP socket ready on 127.0.0.1:%u\\n\", ntohs(address.sin_port));\n    close(fd);\n    return 0;\n}\n",
                expectedSignals: [
                    TutorialLabSignal("端口处于监听或连接成功", marker: "LISTEN"),
                    TutorialLabSignal("HTTP 请求可观察", marker: "HTTP/"),
                    TutorialLabSignal("存在网络错误码分支", marker: "perror", required: false),
                    TutorialLabSignal("程序释放 socket 资源", marker: "close", required: false)
                ],
                failureDrill: "连接到未监听端口，记录 Connection refused；再请求一个存在的端口但关闭服务器，比较连接终止与 HTTP 应用错误。",
                checkpoints: [
                    ("本机连接", "使用 ss 或 curl 确认目标端口状态。", "明确 LISTENING、ESTABLISHED 和 refused 的差别。"),
                    ("协议数据", "保存请求、响应和连接阶段。", "能区分 TCP 连接成功与 HTTP 状态码。"),
                    ("资源生命周期", "检查 socket、bind、listen、accept、close 的顺序。", "错误路径也会关闭已打开 fd。"),
                    ("安全边界", "只在 127.0.0.1 或授权地址实验。", "没有扫描公网或留下长期开放端口。")
                ]
            )

        case "tutorial-compiler":
            return Seed(
                objective: "把表达式文本分词成 token，验证空白、运算符和错误输入，并说明词法阶段不负责语法。",
                scenario: "实现最小词法分析器，输入 `12 + 3 * (4 - 1)`，输出 token 类型和值。",
                expectedSignals: [
                    TutorialLabSignal("识别数字 12", marker: "12"),
                    TutorialLabSignal("识别加号", marker: "+"),
                    TutorialLabSignal("识别乘号", marker: "*"),
                    TutorialLabSignal("遇到非法字符报错", marker: "error", required: false)
                ],
                failureDrill: "输入 `12 $ 3`，确认词法器报告未知字符；不要把语法错误和词法错误混为一谈。",
                checkpoints: [
                    ("正常分词", "保存 token 序列和位置。", "数字、运算符和括号顺序正确。"),
                    ("错误字符", "输入未知字符并检查错误信息。", "错误包含字符和位置。"),
                    ("阶段边界", "解释词法器为什么不能判断括号是否配对。", "能区分词法与语法分析职责。"),
                    ("迁移测试", "增加一个多字符运算符或标识符。", "测试覆盖新增 token 类型。")
                ]
            )

        case "tutorial-database":
            return Seed(
                objective: "用 SQLite 创建表、插入数据、建立索引、观察查询计划，并验证事务回滚。",
                scenario: "在临时数据库中执行建表、查询和回滚，比较有无索引的执行计划。",
                prerequisites: [
                    "macOS 或 Ubuntu 上已安装 sqlite3。",
                    "只使用临时数据库文件。",
                    "知道 DROP/ROLLBACK 会影响实验数据。"
                ],
                terminalCommand: "rm -f /tmp/cs-db.sqlite\nsqlite3 /tmp/cs-db.sqlite <<'SQL'\nCREATE TABLE students(id INTEGER PRIMARY KEY, name TEXT, score INTEGER);\nINSERT INTO students(name, score) VALUES ('Ada', 95), ('Linus', 88), ('Grace', 92);\nSELECT * FROM students WHERE name = 'Grace';\nBEGIN;\nUPDATE students SET score = 100 WHERE name = 'Grace';\nROLLBACK;\nSELECT name, score FROM students;\nEXPLAIN QUERY PLAN SELECT * FROM students WHERE name = 'Grace';\nCREATE INDEX idx_students_name ON students(name);\nEXPLAIN QUERY PLAN SELECT * FROM students WHERE name = 'Grace';\nSQL",
                expectedSignals: [
                    TutorialLabSignal("查询到 Grace", marker: "Grace"),
                    TutorialLabSignal("回滚后分数恢复 92", marker: "92"),
                    TutorialLabSignal("执行计划包含 SEARCH", marker: "SEARCH"),
                    TutorialLabSignal("没有未提交状态", marker: "", required: false)
                ],
                failureDrill: "在事务中插入重复主键，观察错误后执行 ROLLBACK；确认数据库仍可查询且没有半提交数据。",
                checkpoints: [
                    ("基础查询", "创建表并查询指定学生。", "结果只有符合条件的一行。"),
                    ("事务回滚", "更新后回滚并再次查询。", "分数恢复为 92。"),
                    ("索引计划", "比较建索引前后的查询计划。", "能看到 SEARCH 与扫描的差异。"),
                    ("恢复验证", "触发约束错误后回滚。", "数据库仍可打开且没有残留修改。")
                ]
            )

        case "tutorial-specialization":
            return Seed(
                objective: "把学习主题落成一个小型 SwiftUI + SwiftData 作品，并验证构建、搜索、空状态和持久化。",
                scenario: "以一个可运行作品为终点，完成“需求 → 数据模型 → 界面 → 测试 → 复盘”的闭环。",
                prerequisites: [
                    "Xcode 15 或更新版本可用。",
                    "理解 SwiftUI、SwiftData 的基础语法。",
                    "已经选定一条专精方向。"
                ],
                safetyNote: "先在独立示例项目或 Git 分支中实验；不要覆盖现有作品，不要提交密钥和真实用户数据。",
                terminalCommand: "cd ~/Code\n# 用 Xcode 创建 iOS App，选择 SwiftUI + SwiftData\n# 然后运行、预览、测试；以下命令用于记录构建日志\n# xcodebuild -project YourApp.xcodeproj -scheme YourApp -destination 'platform=macOS' build",
                codeLanguage: "text",
                codeOverride: "",
                expectedSignals: [
                    TutorialLabSignal("项目能够构建", marker: "BUILD SUCCEEDED"),
                    TutorialLabSignal("搜索会过滤结果", marker: "search", required: false),
                    TutorialLabSignal("空状态有提示", marker: "empty", required: false),
                    TutorialLabSignal("数据重启后仍存在", marker: "persist", required: false)
                ],
                failureDrill: "删除必填字段或破坏持久化模型后构建，记录编译/迁移错误；用版本化模型或备份恢复，而不是清空用户数据。",
                checkpoints: [
                    ("最小需求", "用一句话定义作品目标和一个非目标。", "范围清晰且可以演示。"),
                    ("数据模型", "列出实体、唯一标识、关系和删除规则。", "没有虚假 API，模型可编译。"),
                    ("用户路径", "完成新增、搜索、详情和空状态。", "每一步有可观察结果。"),
                    ("验证与复盘", "记录构建、测试、失败和下一项改进。", "作品能在干净环境复现。")
                ]
            )

        case "tutorial-math-discrete":
            return Seed(
                objective: "用位集合执行交集、并集与包含判断，并解释集合元素与二进制位的对应关系。",
                scenario: "把八种权限看作一个有限集合，用 C 的无符号整数表示子集，再与 Swift Set 结果对照。",
                expectedSignals: [
                    TutorialLabSignal("用户权限位模式正确", marker: "00000011"),
                    TutorialLabSignal("要求权限位模式正确", marker: "00000101"),
                    TutorialLabSignal("交集只保留读权限", marker: "00000001"),
                    TutorialLabSignal("读权限判断为 yes", marker: "has read = yes")
                ],
                failureDrill: "把权限元素扩展到第 8 位，观察 uint8_t 的边界；再改成动态集合，比较位图与 Set 的空间和时间取舍。",
                checkpoints: [("定义元素范围", "写出权限集合和每个元素对应的位号。", "元素与位号一一对应。"), ("手算集合", "手算并集、交集和差集。", "结果与程序输出一致。"), ("运行验证", "编译运行并保存位模式输出。", "四项输出均可解释。"), ("讨论边界", "说明固定位集合的容量限制。", "能提出位图数组或动态集合方案。")]
            )

        case "tutorial-math-proof":
            return Seed(
                objective: "用循环不变量证明数组求和，并通过断言验证每一轮前缀和。",
                scenario: "把循环初始化、保持和终止三个证明步骤对应到代码。",
                expectedSignals: [
                    TutorialLabSignal("数组和为 14", marker: "sum=14"),
                    TutorialLabSignal("程序退出码为 0", marker: "0"),
                    TutorialLabSignal("断言未触发", marker: "", required: false),
                    TutorialLabSignal("能够说明初始化条件", marker: "", required: false)
                ],
                failureDrill: "把循环条件改成 `i <= count` 或把递增位置改到加法之前，观察不变量何时失效。",
                checkpoints: [("写出不变量", "用一句话说明每轮循环开始和结束时 sum 的含义。", "不变量包含 i 与数组范围。"), ("初始化", "验证循环开始前不变量成立。", "i=0 时 sum 等于空前缀和。"), ("保持", "验证一次迭代不会破坏不变量。", "加入 a[i] 后 i 递增，条件仍成立。"), ("终止", "结合 i==count 推出后置条件。", "sum 等于全部元素之和。")]
            )

        case "tutorial-math-linear":
            return Seed(
                objective: "运行向量点积、模长和旋转矩阵，解释结果分别代表什么几何意义。",
                scenario: "用 Swift 实现二维向量和矩阵，并验证 90 度旋转。",
                expectedSignals: [
                    TutorialLabSignal("点积结果为 3", marker: "dot = 3"),
                    TutorialLabSignal("向量模长为 5", marker: "length = 5"),
                    TutorialLabSignal("旋转结果为 (-4,3)", marker: "-4"),
                    TutorialLabSignal("矩阵顺序影响结果", marker: "rotated")
                ],
                failureDrill: "交换旋转和缩放矩阵的乘法顺序，比较输出并解释为什么线性变换通常不交换。",
                checkpoints: [("手算点积", "计算 (3,4) 与 (1,0) 的点积和模长。", "得到 3 和 5。"), ("运行矩阵", "保存矩阵乘向量输出。", "得到一个二维结果向量。"), ("解释变换", "说明矩阵列向量代表什么。", "能解释基向量被映射到哪里。"), ("比较顺序", "交换两个矩阵并记录差异。", "能说明矩阵乘法不交换。")]
            )

        case "tutorial-math-probability":
            return Seed(
                objective: "用蒙特卡洛模拟估计两枚骰子点数和为 7 的概率，并把结果与理论概率比较。",
                scenario: "重复生成两个 1 到 6 的随机数，统计命中次数并计算经验频率。",
                expectedSignals: [
                    TutorialLabSignal("输出经验频率", marker: "estimate="),
                    TutorialLabSignal("输出理论概率", marker: "theoretical=0.16667"),
                    TutorialLabSignal("程序退出码为 0", marker: "0"),
                    TutorialLabSignal("能够说明随机波动", marker: "", required: false)
                ],
                failureDrill: "把试验次数从一百万降到十次并重复运行，观察估计波动；不要用一次小样本结果否定理论推导。",
                checkpoints: [("定义样本空间", "写出两枚骰子的 36 个等可能结果。", "总数和每个结果概率正确。"), ("理论计算", "找出点数和为 7 的结果数量。", "理论概率为 6/36。"), ("运行模拟", "保存试验次数、命中次数和估计值。", "估计接近 0.1667。"), ("解释波动", "说明样本量与收敛的关系。", "知道模拟不等于证明。")]
            )

        case "tutorial-math-information":
            return Seed(
                objective: "统计不同字符串的字符分布并计算经验熵，解释均匀分布为何熵最大。",
                scenario: "分别计算单符号、两种等概率符号和八种近似均匀符号的熵。",
                expectedSignals: [
                    TutorialLabSignal("单符号熵为 0", marker: "0.000 bit/char"),
                    TutorialLabSignal("两种等概率符号熵为 1", marker: "1.000 bit/char"),
                    TutorialLabSignal("八种符号熵接近 3", marker: "3.000 bit/char"),
                    TutorialLabSignal("输出 bit/char 单位", marker: "bit/char")
                ],
                failureDrill: "把样本改成只有一个符号并重复一千次，观察熵仍为 0；解释消息长度和信息量不是同一个概念。",
                checkpoints: [("频率统计", "写出每个字符的概率估计。", "所有概率非负且总和为 1。"), ("计算熵", "用 -p log2 p 计算并求和。", "结果单位为 bit。"), ("比较分布", "比较三个样本的经验熵。", "结果分别为 0、1、3。"), ("解释边界", "说明经验熵只描述当前样本。", "不会把样本频率当成真实分布。")]
            )

        case "tutorial-theory-automata":
            return Seed(
                objective: "运行接受“以 01 结尾”的 DFA，并手工验证每个输入字符串的状态序列。",
                scenario: "用 0、1、2 三个状态表示起始、刚看到 0、已看到 01，逐个处理输入符号。",
                expectedSignals: [
                    TutorialLabSignal("01 被接受", marker: "01 -> accept"),
                    TutorialLabSignal("101 被接受", marker: "101 -> accept"),
                    TutorialLabSignal("100 被拒绝", marker: "100 -> reject"),
                    TutorialLabSignal("1101 被接受", marker: "1101 -> accept")
                ],
                failureDrill: "修改接受条件为“包含 01”，观察状态机需要增加或调整什么状态；比较识别语言的变化。",
                checkpoints: [("定义状态", "说明三个状态各自表示什么。", "状态含义与转移表一致。"), ("画出转移", "为状态 0、1、2 写出输入 0 和 1 的转移。", "任意状态和输入都有唯一转移。"), ("手工运行", "手工跟踪 101 的状态序列。", "最终到达接受状态。"), ("构造反例", "给出两个应接受和两个应拒绝的字符串。", "测试与语言定义一致。")]
            )

        case "tutorial-theory-computability":
            return Seed(
                objective: "用位掩码枚举小规模子集和，观察指数规模增长并理解 NP 完全问题的工程边界。",
                scenario: "对五个整数枚举全部 32 个子集，判断目标和是否存在。",
                expectedSignals: [
                    TutorialLabSignal("目标 12 可达", marker: "target 12: yes"),
                    TutorialLabSignal("目标 20 可达", marker: "target 20: yes"),
                    TutorialLabSignal("程序退出码为 0", marker: "0"),
                    TutorialLabSignal("能说明 2^n 增长", marker: "", required: false)
                ],
                failureDrill: "把元素数量从 5 改成 30，估算枚举次数而不是实际运行；解释为什么小规模可行不代表通用精确解可行。",
                checkpoints: [("定义判定问题", "写出子集和的输入和 yes/no 输出。", "问题定义没有混入优化目标。"), ("枚举验证", "保存两个目标的命中结果。", "两个目标都可达。"), ("复杂度估算", "写出枚举子集的时间复杂度。", "包含 2^n 因子。"), ("工程策略", "列出至少两种处理大实例的方法。", "方案说明精度和适用条件。")]
            )

        case "tutorial-theory-algorithms":
            return Seed(
                objective: "运行 0/1 背包动态规划，验证状态含义并解释二维转移和一维优化。",
                scenario: "用重量 {2,3,4,5}、价值 {3,4,5,8} 和容量 7 计算最大价值。",
                expectedSignals: [
                    TutorialLabSignal("最大价值为 11", marker: "max value=11"),
                    TutorialLabSignal("输出 dp 状态结果", marker: "max value="),
                    TutorialLabSignal("程序退出码为 0", marker: "0"),
                    TutorialLabSignal("能说明状态定义", marker: "", required: false)
                ],
                failureDrill: "把一维数组改成顺序遍历容量，观察同一物品是否被重复使用；比较 0/1 背包与完全背包。",
                checkpoints: [("定义状态", "说明 dp[i][c] 的含义。", "状态包含物品前缀和容量。"), ("写出转移", "分别写出不选和选择第 i 个物品的结果。", "转移取两者最大值。"), ("手工验证", "手算容量 7 的最优组合。", "得到价值 11。"), ("解释优化", "说明一维逆序遍历为什么正确。", "避免同一物品在同一轮重复使用。")]
            )

        case "tutorial-theory-semantics":
            return Seed(
                objective: "运行订单状态机，验证合法转换并为非法事件返回 nil。",
                scenario: "用 Swift 枚举表示状态和事件，穷尽合法转移，输出所有观察结果。",
                expectedSignals: [
                    TutorialLabSignal("created 可支付", marker: "created -> Optional"),
                    TutorialLabSignal("paid 可发货", marker: "paid -> Optional(cancelled"),
                    TutorialLabSignal("非法事件返回 nil", marker: "nil"),
                    TutorialLabSignal("所有状态都被枚举", marker: "shipped")
                ],
                failureDrill: "为状态机增加 refunded 状态并让编译器指出未覆盖分支；解释穷尽 switch 如何帮助维护不变量。",
                checkpoints: [("定义状态", "列出所有合法订单状态。", "状态互相区分且可持久化。"), ("定义事件", "列出支付、发货和取消事件。", "事件名称表达外部请求。"), ("验证转移", "为每个合法和非法组合保存结果。", "非法组合返回 nil。"), ("讨论并发", "说明并发支付和取消可能如何交错。", "知道单线程状态机不足以直接证明并发安全。")]
            )

        default:
            return nil
        }
    }

    private static func fallback(
        title: String,
        summary: String,
        codeLanguage: String,
        code: String
    ) -> Seed {
        Seed(
            objective: "用一个最小、可重复的实验验证《\(title)》的核心概念，并留下可追溯的证据。",
            scenario: summary,
            terminalCommand: code.isEmpty ? "请根据教程中的最小示例，在临时环境中运行一条可复现命令。" : "",
            codeLanguage: codeLanguage,
            expectedSignals: [
                TutorialLabSignal("正常路径产生预期结果", marker: ""),
                TutorialLabSignal("输入和输出能够被保存", marker: ""),
                TutorialLabSignal("至少一个失败路径可复现", marker: "")
            ],
            failureDrill: "只改变一个输入或配置变量，制造一个可恢复错误，定位根因后重新运行正常路径。",
            checkpoints: [
                ("正常路径", "记录输入、命令、输出和退出状态。", "结果可重复。"),
                ("边界条件", "尝试空值、非法值或资源不足场景。", "失败被清晰报告。"),
                ("证据链", "保存原始输出和版本信息。", "另一位学习者可按记录复现。")
            ]
        )
    }
}
