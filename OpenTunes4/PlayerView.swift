import Foundation
import SwiftUI
import AVFoundation


struct PlayerView: View {
    private var track: Track
    private var asset: AVAsset
    private var duration: TimeInterval
    private var artwork: UIImage
    
    @EnvironmentObject var model: TrackListView.ViewModel
    
    init(track: Track) {
        self.track = track
        let url = URL(string: track.url!)!
        self.asset = AVAsset(url: url)
        self.artwork = getArtwork(asset: self.asset)
        self.duration = TimeInterval(CMTimeGetSeconds(asset.duration))
    }
    
    var body: some View {
        HStack() {
            HStack() {
                Image(uiImage: self.artwork).resizable().frame(width: 50, height: 50)
                VStack(alignment: .leading) {
                    Text(self.track.artist ?? "")
                        .font(.system(.footnote))
                        .opacity(0.7).frame(maxWidth: .infinity)
                    Text(self.track.title ?? "").frame(maxWidth: .infinity)
                }
                Button(action: {
                    self.model.isPlaying ? self.model.stop() : self.model.play(track: self.track)
                }) {
                    Image(systemName: self.model.isPlaying ? "stop.fill" : "play.fill").frame(width: 64)
                }
            }
        }
    }
    
}

#if DEBUG
struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        let urls = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: nil)!
        let viewContext = PersistenceController.preview.container.viewContext
        let track = urlToTrack(context: viewContext, url: urls[0])
        PlayerView(track: track).environmentObject(TrackListView.ViewModel(isPlaying: false))
        PlayerView(track: track).environmentObject(TrackListView.ViewModel(isPlaying: true))
    }
}
#endif
