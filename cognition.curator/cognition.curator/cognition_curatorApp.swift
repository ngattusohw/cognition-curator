//
//  cognition_curatorApp.swift
//  cognition.curator
//
//  Created by Nicholas Gattuso on 7/13/25.
//

import SwiftUI

@main
struct cognition_curatorApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
