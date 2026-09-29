import SwiftData

enum AppSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [
            Stage.self,
            Topic.self,
            Tutorial.self,
            Exercise.self,
            Progress.self,
            Command.self,
            LearningResource.self,
            Concept.self,
            Bookmark.self,
            LearningNote.self,
            ReviewItem.self,
            CodeDraft.self,
            MasteryRecord.self
        ]
    }
}

enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [AppSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
