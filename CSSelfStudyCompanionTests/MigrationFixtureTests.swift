import SwiftData
import XCTest

@Model
final class MigrationFixtureRecord {
    @Attribute(.unique) var id: String
    var title: String
    var value: Int

    init(id: String, title: String, value: Int) {
        self.id = id
        self.title = title
        self.value = value
    }
}

@Model
final class MigrationFixtureTag {
    @Attribute(.unique) var id: String
    var name: String

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

enum MigrationFixtureSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    static var models: [any PersistentModel.Type] { [MigrationFixtureRecord.self] }
}

enum MigrationFixtureSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }
    static var models: [any PersistentModel.Type] {
        [MigrationFixtureRecord.self, MigrationFixtureTag.self]
    }
}

enum MigrationFixturePlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [MigrationFixtureSchemaV1.self, MigrationFixtureSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(
                fromVersion: MigrationFixtureSchemaV1.self,
                toVersion: MigrationFixtureSchemaV2.self
            )
        ]
    }
}

@MainActor
final class MigrationFixtureTests: XCTestCase {
    func testDiskV1ToV2MigrationKeepsExistingDataAndAllowsNewEntity() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("cs-migration-fixture-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let storeURL = directory.appendingPathComponent("migration.store")
        try writeV1Store(at: storeURL)

        let v2Schema = Schema(versionedSchema: MigrationFixtureSchemaV2.self)
        let v2Configuration = ModelConfiguration(
            "MigrationFixture",
            schema: v2Schema,
            url: storeURL
        )
        let container = try ModelContainer(
            for: v2Schema,
            migrationPlan: MigrationFixturePlan.self,
            configurations: [v2Configuration]
        )
        let context = container.mainContext

        let migrated = try context.fetch(FetchDescriptor<MigrationFixtureRecord>())
        XCTAssertEqual(migrated.count, 1)
        XCTAssertEqual(migrated.first?.id, "record-1")
        XCTAssertEqual(migrated.first?.title, "迁移前数据")
        XCTAssertEqual(migrated.first?.value, 42)

        let tag = MigrationFixtureTag(id: "tag-1", name: "V2 新实体")
        context.insert(tag)
        try context.save()
        XCTAssertEqual(try context.fetch(FetchDescriptor<MigrationFixtureTag>()).count, 1)
    }

    private func writeV1Store(at url: URL) throws {
        let schema = Schema(versionedSchema: MigrationFixtureSchemaV1.self)
        let configuration = ModelConfiguration(
            "MigrationFixture",
            schema: schema,
            url: url
        )
        let container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
        let context = container.mainContext
        context.insert(
            MigrationFixtureRecord(
                id: "record-1",
                title: "迁移前数据",
                value: 42
            )
        )
        try context.save()
    }
}
