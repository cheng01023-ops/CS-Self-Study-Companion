import CloudKit
import Combine
import Foundation

enum CloudSyncStatus: Equatable {
    case disabled
    case missingContainer
    case checking
    case available
    case unavailable(String)

    var title: String {
        switch self {
        case .disabled: "未启用"
        case .missingContainer: "未配置"
        case .checking: "检查中"
        case .available: "可用"
        case .unavailable: "不可用"
        }
    }
}

@MainActor
final class CloudSyncService: ObservableObject {
    static let shared = CloudSyncService()

    @Published private(set) var status: CloudSyncStatus = .disabled
    @Published private(set) var lastSyncAt: Date?
    @Published private(set) var isTransferring = false

    private let defaults = UserDefaults.standard
    private let recordID = CKRecord.ID(recordName: "cs-self-study-backup")
    private let recordType = "CSSelfStudyBackup"

    private init() {}

    nonisolated static func configurationState(
        enabled: Bool,
        containerIdentifier: String
    ) -> CloudSyncStatus {
        guard enabled else { return .disabled }
        guard !containerIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .missingContainer
        }
        return .checking
    }

    func refreshStatus() async {
        status = Self.configurationState(
            enabled: defaults.bool(forKey: "cloudSyncEnabled"),
            containerIdentifier: defaults.string(forKey: "cloudKitContainerIdentifier") ?? ""
        )

        guard status == .checking else { return }

        do {
            let container = try configuredContainer()
            let accountStatus = try await accountStatus(for: container)
            switch accountStatus {
            case .available:
                status = .available
            case .noAccount:
                status = .unavailable("iCloud 未登录。请在系统设置中登录 Apple ID。")
            case .restricted:
                status = .unavailable("当前 Apple ID 受限制，无法使用 CloudKit。")
            default:
                status = .unavailable("当前 iCloud 账号状态不可用。")
            }
        } catch {
            status = .unavailable(error.localizedDescription)
        }
    }

    func upload(_ data: Data) async throws {
        await refreshStatus()
        guard status == .available else {
            throw CloudSyncError.notAvailable(status.title)
        }

        isTransferring = true
        defer { isTransferring = false }

        let container = try configuredContainer()
        let database = container.privateCloudDatabase
        let record: CKRecord
        do {
            record = try await database.record(for: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            record = CKRecord(recordType: recordType, recordID: recordID)
        }

        let temporaryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("cs-self-cloud-\(UUID().uuidString).json")
        try data.write(to: temporaryURL, options: .atomic)
        defer { try? FileManager.default.removeItem(at: temporaryURL) }

        record["payload"] = CKAsset(fileURL: temporaryURL)
        record["updatedAt"] = Date() as NSDate
        _ = try await database.save(record)
        lastSyncAt = .now
    }

    func download() async throws -> Data? {
        await refreshStatus()
        guard status == .available else {
            throw CloudSyncError.notAvailable(status.title)
        }

        isTransferring = true
        defer { isTransferring = false }

        let container = try configuredContainer()
        do {
            let record = try await container.privateCloudDatabase.record(for: recordID)
            guard let asset = record["payload"] as? CKAsset,
                  let fileURL = asset.fileURL else {
                return nil
            }
            let data = try Data(contentsOf: fileURL)
            lastSyncAt = .now
            return data
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    private func configuredContainer() throws -> CKContainer {
        guard let identifier = defaults.string(forKey: "cloudKitContainerIdentifier"),
              !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CloudSyncError.missingContainer
        }
        return CKContainer(identifier: identifier)
    }

    private func accountStatus(for container: CKContainer) async throws -> CKAccountStatus {
        try await withCheckedThrowingContinuation { continuation in
            container.accountStatus { status, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: status)
                }
            }
        }
    }
}

enum CloudSyncError: LocalizedError {
    case missingContainer
    case notAvailable(String)

    var errorDescription: String? {
        switch self {
        case .missingContainer:
            "尚未配置 CloudKit Container Identifier。"
        case let .notAvailable(status):
            "CloudKit 当前不可用：\(status)"
        }
    }
}
