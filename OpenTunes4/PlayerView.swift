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
                    self.model.isPlaying ? self.model.pause() : self.model.play(track: nil)
                }) {
                    Image(systemName: self.model.isPlaying ? "pause.fill" : "play.fill")
                        .frame(width: 50, height: 50)
                        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                        .cornerRadius(10.0)
                        
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(10)
        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
        .frame(
            minWidth: nil, idealWidth: nil, maxWidth: .infinity,
            minHeight: 70, idealHeight: 70, maxHeight: 70,
            alignment: .leading)
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
