import SwiftUI
import CoreData
import AVFoundation
import Combine
import MediaPlayer

func getArtwork(asset: AVAsset) -> UIImage {
    let items = AVMetadataItem.metadataItems(from: asset.metadata, filteredByIdentifier: AVMetadataIdentifier.commonIdentifierArtwork)
    let data = items.first?.dataValue
    if data != nil {
        return UIImage(data: data!)!
    }
    return UIImage()
}

struct TrackDetailView: View {
    var track: Track
    var artwork: UIImage
    var asset: AVAsset
    
    init(track: Track) {
        self.track = track
        let url = URL(string: track.url!)!
        self.asset = AVAsset(url: url)
        self.artwork = getArtwork(asset: asset)
    }
    
    var body: some View {
        HStack() {
            Image(uiImage: self.artwork).resizable().frame(width: 50, height: 50)
            Text("Artist: \(track.artist!)")
            Text("Title: \(track.title!)")
            Text("Key: \(track.initialKey!)")
        }
    }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject var model: ViewModel
    
    var body: some View {
        List {
            ForEach(self.model.dataSource) { track in
                TrackDetailView(track: track).listRowInsets(EdgeInsets())
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

struct Platform {

    static var isSimulator: Bool {
        return TARGET_OS_SIMULATOR != 0
    }
}

extension ContentView {
    class ViewModel: ObservableViewModel<Track> {
        private var context: NSManagedObjectContext?
        
        init() {
            super.init(dataSource: [Track]())
        }
        
        func deleteAllTracks(context: NSManagedObjectContext) {
            let fetchRequest = Track.fetchRequest() as NSFetchRequest<Track>
            let coreDataTracks = try! context.fetch(fetchRequest) as [Track]
            for track in coreDataTracks {
                print("Deleting track")
                context.delete(track)
            }
            try! context.save()
        }
        
        func loadTrackFromFile(url: URL, context: NSManagedObjectContext) -> Track {
            let track = Track(context: context)
            let asset = AVAsset(url: url)
            let artist = getTagFilterByIdentifier(asset: asset, identifier: AVMetadataIdentifier.commonIdentifierArtist)
            let title = getTagFilterByIdentifier(asset: asset, identifier: AVMetadataIdentifier.commonIdentifierTitle)
            let initialKey = getTagFilterByIdentifier(asset: asset, identifier: AVMetadataIdentifier.id3MetadataInitialKey)
            let bpm = getTagFilterByIdentifier(asset: asset, identifier: AVMetadataIdentifier.id3MetadataBeatsPerMinute)
            track.artist = artist
            track.title = title
            track.url = url.absoluteString
            track.initialKey = initialKey
            if bpm != "" {
                track.bpm = Double(bpm!)!
            }
            return track
        }
        
        func loadTracksFromLibrary(context: NSManagedObjectContext) {
            let mediaItems: [MPMediaItem] = MPMediaQuery.songs().items!
            let start = DispatchTime.now()
            
            for item in mediaItems {
                let track: Track = Track(context: context)
                track.url = item.assetURL!.absoluteString
                track.artist = item.artist
                track.title = item.title
                try! context.save()
            }
            
            let end = DispatchTime.now()
            let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
            let timeInterval = Double(nanoTime) / 1_000_000_000
            print("Reading tracks took \(timeInterval) seconds")
        }
        
        func loadTracksDB(context: NSManagedObjectContext) {
            let fetchRequest = Track.fetchRequest() as NSFetchRequest<Track>
            let coreDataTracks = try! context.fetch(fetchRequest) as [Track]
            self.dataSource = coreDataTracks
        }
        
        func loadTracks(context: NSManagedObjectContext) {
            deleteAllTracks(context: context)
            
            let urls = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: nil)!
            if Platform.isSimulator {
                for url in urls {
                    let _ = loadTrackFromFile(url: url, context: context)
                    try! context.save()
                }
                self.loadTracksDB(context: context)
            } else {
                MPMediaLibrary.requestAuthorization { status in
                    if status == .authorized {
                        DispatchQueue.main.async {
                            self.loadTracksFromLibrary(context: context)
                            self.loadTracksDB(context: context)
                        }
                    }
                }
            }
        }
    }
}

func getTagFilterByIdentifier(asset: AVAsset, identifier: AVMetadataIdentifier) -> String? {
    let items = AVMetadataItem.metadataItems(from: asset.metadata, filteredByIdentifier: identifier)
    
    if items.count > 0 {
        return items.first!.stringValue
    }
    return ""
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ContentView.ViewModel())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
