//
//  OpenTunes4App.swift
//  OpenTunes4
//
//  Created by Ingo Fischer on 23.11.20.
//

import SwiftUI

@main
struct OpenTunes4App: App {
    let persistenceController = PersistenceController.shared
    
    @StateObject var trackListVM = ContentView.ViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(trackListVM)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
