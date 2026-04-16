//
//  HoppityApp.swift
//  Hoppity
//
//  Created by Sabyasachi Biswas on 16/04/26.
//

import SwiftUI
import CoreData

@main
struct HoppityApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
