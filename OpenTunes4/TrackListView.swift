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

func formatDuration(duration:TimeInterval) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "mm:ss"
    return formatter.string(from: Date(timeIntervalSinceReferenceDate: duration))
}

struct TrackDetailView: View {
    var track: Track
    var artwork: UIImage
    var asset: AVAsset
    var duration: TimeInterval
    
    init(track: Track) {
        self.track = track
        let url = URL(string: track.url!)!
        self.asset = AVAsset(url: url)
        self.artwork = getArtwork(asset: asset)
        self.duration = TimeInterval(CMTimeGetSeconds(asset.duration))
    }
    
    var body: some View {
        HStack() {
            Image(uiImage: self.artwork).resizable().frame(width: 50, height: 50)
            VStack(alignment: .leading) {
                HStack() {
                    Text(self.track.artist ?? "")
                        .font(.system(.footnote))
                        .opacity(0.7)
                    let durationStr = formatDuration(duration: self.duration)
                    Spacer()
                    Text("\(durationStr)")
                        .font(.system(.footnote))
                        .opacity(0.7)
                }
                
                Text(self.track.title ?? "")
                HStack() {
                    Text(self.track.initialKey ?? "")
                        .font(.system(.footnote))
                        .opacity(0.7)
                    if self.track.bpm != 0 {
                        Text("\(Int(self.track.bpm))bpm")
                            .font(.system(.footnote))
                            .opacity(0.7)
                    }
                }
            }
        }.padding()
    }
}

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

func getTagFilterByIdentifier(asset: AVAsset, identifier: AVMetadataIdentifier) -> String? {
    let items = AVMetadataItem.metadataItems(from: asset.metadata, filteredByIdentifier: identifier)
    
    if items.count > 0 {
        return items.first!.stringValue
    }
    return ""
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        TrackListView()
            .environmentObject(TrackListView.ViewModel())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        
//        var vm = TrackListView.ViewModel()
//        vm.loadTracksFromLibrary(context: vm.context)
//        TrackDetailView(vm)
    }
}
