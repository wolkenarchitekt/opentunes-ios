//
//  ContentView.swift
//  OpenTunes4
//
//  Created by Ingo Fischer on 23.11.20.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject var model: ViewModel
    
    var body: some View {
        List {
            ForEach(self.model.dataSource) { track in
                Text("Artist: \(track.artist!)")
                Text("Title: \(track.title!)")
            }
        }
        .onAppear() {
            self.model.loadTracks(context: viewContext)
        }
    }
}

class ObservableViewModel<T>: ObservableObject {
    @Published public var dataSource: [T]

    init(dataSource: [T]) {
        self.dataSource = dataSource
    }
}

extension ContentView {
    class ViewModel: ObservableViewModel<Track> {
        var context: NSManagedObjectContext?
        
        init() {
            self.context = nil
            super.init(dataSource: [Track]())
        }
        
        func loadTracks(context: NSManagedObjectContext) {
            self.context = context
            let fetchRequest = Track.fetchRequest() as NSFetchRequest<Track>
            let coreDataItems = try! context.fetch(fetchRequest) as [Track]
            dataSource = coreDataItems
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ContentView.ViewModel())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
