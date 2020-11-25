import SwiftUI
import CoreData
import AVFoundation

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
        
        func deleteAllTracks(context: NSManagedObjectContext) {
            var fetchRequest = Track.fetchRequest() as NSFetchRequest<Track>
            let coreDataTracks = try! context.fetch(fetchRequest) as [Track]
            for track in coreDataTracks {
                print("Deleting track")
                context.delete(track)
            }
            try! context.save()
        }
        
        func loadTracks(context: NSManagedObjectContext) {
            self.context = context
            
            deleteAllTracks(context: context)
            
            let urls = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: nil)!
            print("got tracks: \(urls.count)")
            
            for url in urls {
                let asset = AVAsset(url: url)
                let artist = getTagFilterByIdentifier(asset: asset, identifier: AVMetadataIdentifier.commonIdentifierArtist)
                let title = getTagFilterByIdentifier(asset: asset, identifier: AVMetadataIdentifier.commonIdentifierTitle)
                let url = url.relativeString
                
                let track = Track(context: context)
                track.artist = artist
                track.title = title
                track.url = url
                try! context.save()
            }
            
            let fetchRequest = Track.fetchRequest() as NSFetchRequest<Track>
            let coreDataTracks = try! context.fetch(fetchRequest) as [Track]
            dataSource = coreDataTracks
        }
    }
}

func getTagFilterByIdentifier(asset: AVAsset, identifier: AVMetadataIdentifier) -> String? {
    let items = AVMetadataItem.metadataItems(from: asset.metadata, filteredByIdentifier: identifier)
    
    if items.count > 0 {
        return items.first!.stringValue
    } else {
        return ""
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ContentView.ViewModel())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
