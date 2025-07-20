import Foundation
import CoreData
import Combine
import Network

// MARK: - Sync Status Enums

enum SyncStatus: String, CaseIterable {
    case synced = "synced"         // Successfully synced with backend
    case pending = "pending"       // Waiting to be synced
    case failed = "failed"         // Sync failed, will retry
    case conflict = "conflict"     // Conflict detected, needs resolution
}

enum SyncOperationType: String, CaseIterable {
    case create = "create"
    case update = "update"
    case delete = "delete"
    case review = "review"         // Special operation for review sessions
}

enum SyncPriority: Int16, CaseIterable {
    case low = 1
    case normal = 2
    case high = 3
    case critical = 4             // User-initiated actions
}



// MARK: - Offline Sync Service

@MainActor
class OfflineSyncService: ObservableObject {
    static let shared = OfflineSyncService()

    @Published var syncProgress: Double = 0.0
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var pendingOperationsCount = 0

    private let persistenceController = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()
    private let networkMonitor = NetworkMonitor.shared

    private init() {
        setupNetworkMonitoring()
        updatePendingOperationsCount()
    }

    private func setupNetworkMonitoring() {
        networkMonitor.$isConnected
            .dropFirst() // Skip initial value
            .filter { $0 } // Only when connection is restored
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.syncPendingOperations()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Offline Operations Queue

    func queueSyncOperation(
        entityType: String,
        entityId: String,
        operation: SyncOperationType,
        payload: [String: Any],
        priority: SyncPriority = .normal
    ) {
        print("📥 OfflineSyncService: Queuing \(operation.rawValue) for \(entityType) - \(entityId)")

        let context = persistenceController.container.viewContext

        // Check if operation already exists
        let fetchRequest: NSFetchRequest<SyncOperation> = SyncOperation.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "entityType == %@", entityType),
            NSPredicate(format: "entityId == %@", entityId),
            NSPredicate(format: "operation == %@", operation.rawValue),
            NSPredicate(format: "status == %@", SyncStatus.pending.rawValue)
        ])

        do {
            let existingOperations = try context.fetch(fetchRequest)
            if !existingOperations.isEmpty {
                print("⚠️ OfflineSyncService: Operation already queued for \(entityType) - \(entityId)")
                return
            }

            let syncOp = SyncOperation(context: context)
            syncOp.id = UUID()
            syncOp.entityType = entityType
            syncOp.entityId = entityId
            syncOp.operation = operation.rawValue
            syncOp.payload = payload
            syncOp.priority = priority.rawValue
            syncOp.status = SyncStatus.pending.rawValue
            syncOp.createdAt = Date()
            syncOp.retryCount = 0

            try context.save()
            updatePendingOperationsCount()

            print("✅ OfflineSyncService: Operation queued successfully")

            // Try immediate sync if connected
            if networkMonitor.isConnected {
                Task { @MainActor in
                    await syncSingleOperation(syncOp)
                }
            }
        } catch {
            print("❌ OfflineSyncService: Failed to queue operation: \(error)")
        }
    }

    // MARK: - Sync Operations

    func syncPendingOperations() async {
        guard networkMonitor.isConnected else {
            print("📴 OfflineSyncService: No network connection, skipping sync")
            return
        }

        guard !isSyncing else {
            print("🔄 OfflineSyncService: Sync already in progress")
            return
        }

        isSyncing = true
        syncProgress = 0.0

        print("🚀 OfflineSyncService: Starting sync of pending operations")

        let context = persistenceController.container.newBackgroundContext()

        let fetchRequest: NSFetchRequest<SyncOperation> = SyncOperation.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "status == %@", SyncStatus.pending.rawValue)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "priority", ascending: false),
            NSSortDescriptor(key: "createdAt", ascending: true)
        ]

        do {
            let pendingOperations = try context.fetch(fetchRequest)
            print("📊 OfflineSyncService: Found \(pendingOperations.count) pending operations")

            if pendingOperations.isEmpty {
                isSyncing = false
                syncProgress = 1.0
                lastSyncDate = Date()
                return
            }

            let totalOperations = Double(pendingOperations.count)

            for (index, operation) in pendingOperations.enumerated() {
                await syncSingleOperation(operation)
                syncProgress = Double(index + 1) / totalOperations
            }

            isSyncing = false
            syncProgress = 1.0
            lastSyncDate = Date()
            updatePendingOperationsCount()

        } catch {
            print("❌ OfflineSyncService: Failed to fetch pending operations: \(error)")
            isSyncing = false
        }
    }

    private func syncSingleOperation(_ operation: SyncOperation) async {
        guard let entityType = operation.entityType,
              let entityId = operation.entityId,
              let operationType = operation.operation else {
            print("❌ OfflineSyncService: Invalid operation data")
            return
        }

        let payload: [String: Any]
        if let payloadDict = operation.payload as? [String: Any] {
            payload = payloadDict
        } else {
            payload = [:]
        }
        print("🔄 OfflineSyncService: Syncing \(operationType) for \(entityType) - \(entityId)")

        var success = false

        switch (entityType, operationType) {
        case ("ReviewSession", "create"), ("ReviewSession", "review"):
            success = await syncReviewSession(payload: payload)
        case ("Deck", "create"):
            success = await syncDeckCreation(payload: payload)
        case ("Deck", "update"):
            success = await syncDeckUpdate(entityId: entityId, payload: payload)
        case ("Flashcard", "create"):
            success = await syncFlashcardCreation(payload: payload)
        case ("Flashcard", "update"):
            success = await syncFlashcardUpdate(entityId: entityId, payload: payload)
        default:
            print("⚠️ OfflineSyncService: Unknown operation type: \(entityType).\(operationType)")
        }

                // Update operation status
        let context = operation.managedObjectContext ?? persistenceController.container.viewContext
        await context.perform {
            if success {
                operation.status = SyncStatus.synced.rawValue
                print("✅ OfflineSyncService: Operation synced successfully")
            } else {
                operation.retryCount += 1
                if operation.retryCount >= 3 {
                    operation.status = SyncStatus.failed.rawValue
                    print("❌ OfflineSyncService: Operation failed after 3 retries")
                } else {
                    print("⚠️ OfflineSyncService: Operation failed, will retry (\(operation.retryCount)/3)")
                }
            }

            do {
                try context.save()
            } catch {
                print("❌ OfflineSyncService: Failed to update operation status: \(error)")
            }
        }
    }

    // MARK: - Specific Sync Methods

        private func syncReviewSession(payload: [String: Any]) async -> Bool {
        let reviewSync = FlashcardReviewSync(
            flashcardId: payload["flashcard_id"] as? String ?? "",
            difficultyRating: payload["difficulty_rating"] as? Int ?? 0,
            wasCorrect: payload["was_correct"] as? Bool ?? false,
            responseTimeSeconds: payload["response_time_seconds"] as? Double ?? 0.0,
            sessionType: payload["session_type"] as? String ?? "general_review",
            deviceType: payload["device_type"] as? String ?? "ios",
            appVersion: payload["app_version"] as? String,
            easeFactorBefore: payload["ease_factor_before"] as? Double,
            easeFactorAfter: payload["ease_factor_after"] as? Double,
            intervalBeforeDays: payload["interval_before_days"] as? Int,
            intervalAfterDays: payload["interval_after_days"] as? Int,
            repetitionsBefore: payload["repetitions_before"] as? Int,
            repetitionsAfter: payload["repetitions_after"] as? Int,
            confidenceLevel: payload["confidence_level"] as? Double,
            hintUsed: payload["hint_used"] as? Bool ?? false,
            multipleAttempts: payload["multiple_attempts"] as? Bool ?? false
        )

        return await withCheckedContinuation { continuation in
            AnalyticsAPIService.shared.syncFlashcardReview(reviewSync)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { success in
                        continuation.resume(returning: success)
                    }
                )
                .store(in: &cancellables)
        }
    }

    private func syncDeckCreation(payload: [String: Any]) async -> Bool {
        // Implementation for deck creation sync
        // This would use DeckAPIService to create deck on backend
        return true // Placeholder
    }

    private func syncDeckUpdate(entityId: String, payload: [String: Any]) async -> Bool {
        // Implementation for deck update sync
        return true // Placeholder
    }

    private func syncFlashcardCreation(payload: [String: Any]) async -> Bool {
        // Implementation for flashcard creation sync
        return true // Placeholder
    }

    private func syncFlashcardUpdate(entityId: String, payload: [String: Any]) async -> Bool {
        // Implementation for flashcard update sync
        return true // Placeholder
    }

    // MARK: - Helper Methods

    private func updatePendingOperationsCount() {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<SyncOperation> = SyncOperation.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "status == %@", SyncStatus.pending.rawValue)

        do {
            let count = try context.count(for: fetchRequest)
            pendingOperationsCount = count
            print("📊 OfflineSyncService: \(count) pending operations")
        } catch {
            print("❌ OfflineSyncService: Failed to count pending operations: \(error)")
        }
    }

    func markEntityForSync(entityType: String, entityId: String, operation: SyncOperationType, priority: SyncPriority = .normal) {
        let context = persistenceController.container.viewContext

        // Update entity sync status
        switch entityType {
        case "Deck":
            updateDeckSyncStatus(entityId: entityId, needsSync: true, context: context)
        case "Flashcard":
            updateFlashcardSyncStatus(entityId: entityId, needsSync: true, context: context)
        case "ReviewSession":
            updateReviewSessionSyncStatus(entityId: entityId, needsSync: true, context: context)
        default:
            break
        }
    }

        private func updateDeckSyncStatus(entityId: String, needsSync: Bool, context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Deck> = NSFetchRequest(entityName: "Deck")
        let uuidValue = UUID(uuidString: entityId) ?? UUID()
        fetchRequest.predicate = NSPredicate(format: "id == %@", uuidValue as NSUUID)

        do {
            let decks = try context.fetch(fetchRequest)
            if let deck = decks.first {
                deck.needsSync = needsSync
                deck.syncStatus = needsSync ? SyncStatus.pending.rawValue : SyncStatus.synced.rawValue
                deck.updatedAt = Date()
                try context.save()
            }
        } catch {
            print("❌ OfflineSyncService: Failed to update deck sync status: \(error)")
        }
    }

        private func updateFlashcardSyncStatus(entityId: String, needsSync: Bool, context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Flashcard> = NSFetchRequest(entityName: "Flashcard")
        let uuidValue = UUID(uuidString: entityId) ?? UUID()
        fetchRequest.predicate = NSPredicate(format: "id == %@", uuidValue as NSUUID)

        do {
            let flashcards = try context.fetch(fetchRequest)
            if let flashcard = flashcards.first {
                flashcard.needsSync = needsSync
                flashcard.syncStatus = needsSync ? SyncStatus.pending.rawValue : SyncStatus.synced.rawValue
                flashcard.updatedAt = Date()
                try context.save()
            }
        } catch {
            print("❌ OfflineSyncService: Failed to update flashcard sync status: \(error)")
        }
    }

        private func updateReviewSessionSyncStatus(entityId: String, needsSync: Bool, context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<ReviewSession> = NSFetchRequest(entityName: "ReviewSession")
        let uuidValue = UUID(uuidString: entityId) ?? UUID()
        fetchRequest.predicate = NSPredicate(format: "id == %@", uuidValue as NSUUID)

        do {
            let sessions = try context.fetch(fetchRequest)
            if let session = sessions.first {
                session.needsSync = needsSync
                session.syncStatus = needsSync ? SyncStatus.pending.rawValue : SyncStatus.synced.rawValue
                try context.save()
            }
        } catch {
            print("❌ OfflineSyncService: Failed to update review session sync status: \(error)")
        }
    }

    // MARK: - Conflict Resolution

    func resolveConflict(operation: SyncOperation, resolution: ConflictResolution) async {
        // Implementation for conflict resolution
        // This would handle cases where local and remote data differ
    }

    // MARK: - Manual Sync Trigger

    func forceSyncAll() async {
        print("🔄 OfflineSyncService: Force sync requested")
        await syncPendingOperations()
    }

    // MARK: - Cleanup

    func cleanupSyncedOperations() {
        let context = persistenceController.container.viewContext

        // Remove operations older than 7 days that are synced
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        let fetchRequest: NSFetchRequest<SyncOperation> = SyncOperation.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "status == %@", SyncStatus.synced.rawValue),
            NSPredicate(format: "lastSyncedAt < %@", cutoffDate as NSDate)
        ])

        do {
            let oldOperations = try context.fetch(fetchRequest)
            for operation in oldOperations {
                context.delete(operation)
            }
            try context.save()
            print("🧹 OfflineSyncService: Cleaned up \(oldOperations.count) old sync operations")
        } catch {
            print("❌ OfflineSyncService: Failed to cleanup sync operations: \(error)")
        }
    }
}

// MARK: - Conflict Resolution Types

enum ConflictResolution {
    case useLocal
    case useRemote
    case merge
}

// MARK: - Extensions for Core Data Models

extension Deck {
    func markForSync(operation: SyncOperationType) {
        Task { @MainActor in
            OfflineSyncService.shared.markEntityForSync(
                entityType: "Deck",
                entityId: self.id?.uuidString ?? "",
                operation: operation
            )
        }
    }
}

extension Flashcard {
    func markForSync(operation: SyncOperationType) {
        Task { @MainActor in
            OfflineSyncService.shared.markEntityForSync(
                entityType: "Flashcard",
                entityId: self.id?.uuidString ?? "",
                operation: operation
            )
        }
    }
}

extension ReviewSession {
    func markForSync(operation: SyncOperationType) {
        Task { @MainActor in
            OfflineSyncService.shared.markEntityForSync(
                entityType: "ReviewSession",
                entityId: self.id?.uuidString ?? "",
                operation: operation
            )
        }
    }
}