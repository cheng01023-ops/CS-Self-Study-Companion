import Foundation

struct RemoteCodeRequest: Codable, Equatable {
    let id: String
    let code: String
    let language: String
    let input: String
    let arguments: [String]
    let expectedOutput: String
}

struct RemoteCodeResponse: Codable {
    let id: String
    let result: CodeRunResult
}

enum SyncEnvelope: Codable {
    case backup(Data)
    case delta(SyncDelta)
    case codeRequest(RemoteCodeRequest)
    case codeResponse(RemoteCodeResponse)
}

enum RemoteCodeExecutionService {
    static func run(
        code: String,
        language: String,
        input: String,
        arguments: [String] = [],
        expectedOutput: String
    ) async -> CodeRunResult {
        await SyncManager.shared.requestRemoteCode(
            code: code,
            language: language,
            input: input,
            arguments: arguments,
            expectedOutput: expectedOutput
        )
    }
}
