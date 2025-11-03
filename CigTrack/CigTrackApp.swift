//
//  CigTrackApp.swift
//  CigTrack
//
//  Created by Yan on 4/11/25.
//

import SwiftUI
import CoreData

@main
struct CigTrackApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
