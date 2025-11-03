//
//  CigTrackApp.swift
//  CigTrack
//
//  Created by Yan on 4/11/25.
//

import SwiftUI
import CoreData

@main
struct PuffQuestApp: App {
    private let persistenceController = PersistenceController.shared
    @StateObject private var appViewModel = AppViewModel(context: PersistenceController.shared.container.viewContext)

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(appViewModel)
        }
    }
}
