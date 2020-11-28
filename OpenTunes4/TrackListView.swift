import SwiftUI
import CoreData
import AVFoundation
import Combine
import MediaPlayer




struct TrackListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject var model: ViewModel
    
    let color = Color(red: 0.6078, green: 0.3961, blue: 0)
    
    var body: some View {
        VStack() {
            List {
                ForEach(self.model.dataSource) { track in
                    Button(action: {
                        self.model.play(track: track)
                    }) {
                        TrackDetailView(track: track)
                            .background(track.url == self.model.currentTrack?.url ? color : nil)
                    }
                }
            }.onAppear() {
                self.model.loadTracks(context: viewContext)
            }
            if self.model.currentTrack != nil {
                PlayerView(track: self.model.currentTrack!)
            }
        }
    }
}

extension TrackListView {
    class ViewModel: ObservableViewModel<Track> {
        @Published var currentTrack: Track?
        @Published var player: AVPlayer
        @Published var isPlaying: Bool
        
        init(isPlaying: Bool = false) {
            player = AVPlayer()
            self.isPlaying = isPlaying
            super.init(dataSource: [Track]())
        }
        
        func play(track: Track) {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print(error.localizedDescription)
            }
            self.player.pause()
            let item = AVPlayerItem(url: URL(string: track.url!)!)
            self.player.replaceCurrentItem(with: item)
            self.player.play()
            self.currentTrack = track
            self.isPlaying = true
            self.objectWillChange.send()
        }
        
        func stop() {
            self.player.pause()
            self.isPlaying = false
            self.objectWillChange.send()
        }
        
        private func deleteAllTracks(context: NSManagedObjectContext) {
            let fetchRequest = Track.fetchRequest() as NSFetchRequest<Track>
            let coreDataTracks = try! context.fetch(fetchRequest) as [Track]
            for track in coreDataTracks {
                context.delete(track)
            }
            try! context.save()
        }
        
        private func fetchTrackByUrl(context: NSManagedObjectContext, url: URL) -> Track? {
            let fetchRequest = Track.fetchRequest() as NSFetchRequest<Track>
            let predicate = NSPredicate(format: "url == %@", url.relativeString)
            fetchRequest.predicate = predicate
            fetchRequest.fetchLimit = 1
            let track = try! context.fetch(fetchRequest)
            return track.first
        }
        
        private func loadTracksFromLibrary(context: NSManagedObjectContext) {
            let mediaItems: [MPMediaItem] = MPMediaQuery.songs().items!
            let start = DispatchTime.now()
            
            for item in mediaItems {
                let trackDB = fetchTrackByUrl(context: context, url: item.assetURL!)
                if trackDB == nil {
                    let track = urlToTrack(context: context, url: item.assetURL!)
                    track.dateAdded = item.dateAdded
                    try! context.save()
                }
            }
            
            let end = DispatchTime.now()
            let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
            let timeInterval = Double(nanoTime) / 1_000_000_000
            print("Reading tracks took \(timeInterval) seconds")
        }
        
        private func loadTracksFromDB(context: NSManagedObjectContext) {
            let fetchRequest = Track.fetchRequest() as NSFetchRequest<Track>
            self.dataSource = try! context.fetch(fetchRequest) as [Track]
        }
        
        func loadTracks(context: NSManagedObjectContext) {
            if Platform.isSimulator {
                deleteAllTracks(context: context)
                
                let urls = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: nil)!

                for url in urls {
                    let track = urlToTrack(context: context, url: url)
                    track.dateAdded = fileDateAdded(url: url)
                    try! context.save()
                }
                self.loadTracksFromDB(context: context)
                self.currentTrack = dataSource[0]
            } else {
                MPMediaLibrary.requestAuthorization { status in
                    if status == .authorized {
                        DispatchQueue.main.async {
                            self.loadTracksFromLibrary(context: context)
                            self.loadTracksFromDB(context: context)
                            self.currentTrack = self.dataSource[0]
                        }
                    }
                }
            }
        }
    }
}

#if DEBUG
struct TrackListView_Previews: PreviewProvider {
    static var previews: some View {
        TrackListView()
            .environmentObject(TrackListView.ViewModel())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
#endif
