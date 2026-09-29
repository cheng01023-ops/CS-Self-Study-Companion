import XCTest
@testable import CSSelfStudyCompanion

final class SyncProtocolTests: XCTestCase {
    func testCodeRequestEnvelopeRoundTrips() throws {
        let request = RemoteCodeRequest(
            id: "request-1",
            code: "int main(void) { return 0; }",
            language: "c",
            input: "input",
            arguments: ["one"],
            expectedOutput: "output"
        )
        let encoded = try JSONEncoder().encode(SyncEnvelope.codeRequest(request))
        let decoded = try JSONDecoder().decode(SyncEnvelope.self, from: encoded)

        guard case let .codeRequest(decodedRequest) = decoded else {
            return XCTFail("Expected code request")
        }
        XCTAssertEqual(decodedRequest, request)
    }

    func testCodeResponseEnvelopeRoundTrips() throws {
        let response = RemoteCodeResponse(
            id: "response-1",
            result: CodeRunResult(
                succeeded: true,
                passed: true,
                stdout: "42\n",
                stderr: "",
                exitCode: 0,
                timedOut: false,
                message: "运行通过"
            )
        )
        let encoded = try JSONEncoder().encode(SyncEnvelope.codeResponse(response))
        let decoded = try JSONDecoder().decode(SyncEnvelope.self, from: encoded)

        guard case let .codeResponse(decodedResponse) = decoded else {
            return XCTFail("Expected code response")
        }
        XCTAssertEqual(decodedResponse.id, response.id)
        XCTAssertTrue(decodedResponse.result.passed)
    }

    func testDeltaEnvelopeRoundTrips() throws {
        let delta = SyncDelta(
            generatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            isFullSnapshot: false,
            progress: [],
            bookmarks: [],
            notes: [],
            reviewItems: [],
            codeDrafts: [],
            masteryRecords: [],
            deletedProgress: [SyncDeletion(key: "progress-one", deletedAt: .now)],
            deletedBookmarks: [],
            deletedNotes: [],
            deletedReviews: [],
            deletedDrafts: [],
            deletedMastery: []
        )
        let encoded = try JSONEncoder().encode(SyncEnvelope.delta(delta))
        let decoded = try JSONDecoder().decode(SyncEnvelope.self, from: encoded)

        guard case let .delta(decodedDelta) = decoded else {
            return XCTFail("Expected delta")
        }
        XCTAssertFalse(decodedDelta.isFullSnapshot)
        XCTAssertEqual(decodedDelta.deletedProgress.first?.key, "progress-one")
    }

    @MainActor
    func testRemoteCodeWithoutPeerReturnsActionableFailure() async {
        let result = await RemoteCodeExecutionService.run(
            code: "int main(void) { return 0; }",
            language: "c",
            input: "",
            expectedOutput: ""
        )

        XCTAssertFalse(result.succeeded)
        XCTAssertTrue(result.message.contains("同步服务") || result.message.contains("Mac"))
    }
}
