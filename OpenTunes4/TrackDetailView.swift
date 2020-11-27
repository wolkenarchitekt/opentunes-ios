import Foundation
import SwiftUI
import AVFoundation


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
                    Text(formatDate(date: self.track.dateAdded!))
                        .font(.system(.footnote))
                        .opacity(0.7)
                }
            }
        }.padding()
    }
}
