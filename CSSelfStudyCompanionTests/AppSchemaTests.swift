import SwiftData
import XCTest
@testable import CSSelfStudyCompanion

final class AppSchemaTests: XCTestCase {
    func testVersionedSchemaContainsAllPersistentModels() {
        XCTAssertEqual(AppSchemaV1.versionIdentifier, Schema.Version(1, 0, 0))
        XCTAssertEqual(AppSchemaV1.models.count, 13)
        XCTAssertEqual(AppMigrationPlan.schemas.count, 1)
        XCTAssertTrue(AppMigrationPlan.stages.isEmpty)
    }

    @MainActor
    func testVersionedSchemaCreatesInMemoryContainer() throws {
        let schema = Schema(versionedSchema: AppSchemaV1.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: schema,
            migrationPlan: AppMigrationPlan.self,
            configurations: [configuration]
        )

        XCTAssertTrue(try container.mainContext.fetch(FetchDescriptor<CSSelfStudyCompanion.Progress>()).isEmpty)
    }
}
