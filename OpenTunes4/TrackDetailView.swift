import Foundation
import SwiftUI
import AVFoundation


struct TrackDetailView: View {
    var track: Track
    var artwork: UIImage
    var asset: AVAsset
    var duration: TimeInterval
    let color = Color(red: 0.6078, green: 0.3961, blue: 0)
    
    @EnvironmentObject var model: TrackListView.ViewModel
    
    init(track: Track) {
        self.track = track
        let url = URL(string: track.url!)!
        self.asset = AVAsset(url: url)
        self.artwork = getArtwork(asset: asset)
        self.duration = TimeInterval(CMTimeGetSeconds(asset.duration))
    }
    
    var body: some View {
        HStack() {
            Button(action: {
                self.model.isPaused = false
                self.model.play(track: track)
            }) {
                HStack() {
                    Image(uiImage: self.artwork).resizable().frame(width: 50, height: 50)
                    VStack(alignment: .leading) {
                        HStack() {
                            Text(self.track.artist ?? "")
                                .font(.system(.footnote))
                                .opacity(0.7)
                            Spacer()
                            let durationStr = formatDuration(duration: self.duration)
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
                            if self.track.dateAdded != nil {
                                Text(formatDate(date: self.track.dateAdded!))
                                    .font(.system(.footnote))
                                    .opacity(0.7)
                            }
                        }
                    }
                }
            }
        }
        .padding(10)
        .frame(
            minWidth: nil, idealWidth: nil, maxWidth: nil,
            minHeight: 70, idealHeight: 70, maxHeight: 70,
            alignment: .leading)
        .background(track.url == self.model.currentTrack?.url ? color : nil)
    }
}

#if DEBUG
struct TrackDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let url = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: nil)![0]
        let viewContext = PersistenceController.preview.container.viewContext
        let track = urlToTrack(context: viewContext, url: url)
        TrackDetailView(track: track)
    }
}
#endif
