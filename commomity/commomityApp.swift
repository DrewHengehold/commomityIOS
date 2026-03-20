//
//  commomityApp.swift
//  commomity
//
//  Created by Drew Hengehold on 3/20/26.
//

import SwiftUI
import CoreData

@main
struct commomityApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
