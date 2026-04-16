//
//  Persistence.swift
//  Hoppity
//
//  Created by Sabyasachi Biswas on 16/04/26.
//

import CoreData
import OSLog

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview = PersistenceController(inMemory: true)

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Hoppity")
        let logger = Logger(subsystem: "com.hoppity.app", category: "Persistence")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error {
                logger.error("Persistent store failed to load: \(error.localizedDescription, privacy: .public)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
