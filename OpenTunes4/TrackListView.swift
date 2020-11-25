import SwiftUI
import CoreData
import AVFoundation
import Combine
import MediaPlayer


struct TrackListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject var model: ViewModel
    
    var body: some View {
        VStack() {
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
}

extension TrackListView {
    class ViewModel: ObservableViewModel<Track> {
        private var context: NSManagedObjectContext?
        
        init() {
            super.init(dataSource: [Track]())
        }
        
        func deleteAllTracks(context: NSManagedObjectContext) {
            let fetchRequest = Track.fetchRequest() as NSFetchRequest<Track>
            let coreDataTracks = try! context.fetch(fetchRequest) as [Track]
            for track in coreDataTracks {
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
        
        func fetchTrackByUrl(context: NSManagedObjectContext, url: URL) -> Track? {
            let fetchRequest = Track.fetchRequest() as NSFetchRequest<Track>
            let predicate = NSPredicate(format: "url == %@", url.relativeString)
            fetchRequest.predicate = predicate
            fetchRequest.fetchLimit = 1
            let track = try! context.fetch(fetchRequest)
            return track.first
        }
        
        func loadTracksFromLibrary(context: NSManagedObjectContext) {
            let mediaItems: [MPMediaItem] = MPMediaQuery.songs().items!
            let start = DispatchTime.now()
            
            for item in mediaItems {
                var track: Track
                if let trackDB = fetchTrackByUrl(context: context, url: item.assetURL!) {
                    track = trackDB
                } else {
                    track = Track(context: context)
                    track.url = item.assetURL!.absoluteString
                    track.artist = item.artist
                    track.title = item.title
                    let asset = AVAsset(url: item.assetURL!)
                    if let initialKey = getTagFilterByIdentifier(asset: asset, identifier: AVMetadataIdentifier.id3MetadataInitialKey) {
                        track.initialKey = initialKey
                    }
                    let bpmStr = getTagFilterByIdentifier(asset: asset, identifier: AVMetadataIdentifier.id3MetadataBeatsPerMinute)
                    if bpmStr != "" {
                        track.bpm = Double(bpmStr!)!
                    }
                    try! context.save()
                }
            }
            
            let end = DispatchTime.now()
            let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
            let timeInterval = Double(nanoTime) / 1_000_000_000
            print("Reading tracks took \(timeInterval) seconds")
        }
        
        func loadTracksFromDB(context: NSManagedObjectContext) {
            let fetchRequest = Track.fetchRequest() as NSFetchRequest<Track>
            let coreDataTracks = try! context.fetch(fetchRequest) as [Track]
            self.dataSource = coreDataTracks
        }
        
        func loadTracks(context: NSManagedObjectContext) {
            let urls = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: nil)!
            
            if Platform.isSimulator {
                deleteAllTracks(context: context)
                
                for url in urls {
                    let _ = loadTrackFromFile(url: url, context: context)
                    try! context.save()
                }
                self.loadTracksFromDB(context: context)
            } else {
                MPMediaLibrary.requestAuthorization { status in
                    if status == .authorized {
                        DispatchQueue.main.async {
                            self.loadTracksFromLibrary(context: context)
                            self.loadTracksFromDB(context: context)
                        }
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        TrackListView()
            .environmentObject(TrackListView.ViewModel())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
