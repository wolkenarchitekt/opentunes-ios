import SwiftUI

@main
struct OpenTunes4App: App {
    let persistenceController = PersistenceController.shared
    
    @StateObject var trackListVM = TrackListView.ViewModel()

    var body: some Scene {
        WindowGroup {
            TrackListView()
                .environmentObject(trackListVM)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
