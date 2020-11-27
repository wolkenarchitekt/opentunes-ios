import Foundation
import AVFoundation
import SwiftUI
import CoreData


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

func getTagFilterByIdentifier(asset: AVAsset, identifier: AVMetadataIdentifier) -> String? {
    let items = AVMetadataItem.metadataItems(from: asset.metadata, filteredByIdentifier: identifier)
    
    if items.count > 0 {
        return items.first!.stringValue
    }
    return ""
}

struct Platform {
    static var isSimulator: Bool {
        return TARGET_OS_SIMULATOR != 0
    }
}

class ObservableViewModel<T>: ObservableObject {
    @Published public var dataSource: [T]

    init(dataSource: [T]) {
        self.dataSource = dataSource
    }
}

func urlToTrack(context: NSManagedObjectContext, url: URL) -> Track {
    let track = Track(context: context)
    track.url = url.absoluteString
    
    let asset = AVAsset(url: url)
    track.artist = getTagFilterByIdentifier(asset: asset, identifier: AVMetadataIdentifier.commonIdentifierArtist)
    track.title = getTagFilterByIdentifier(asset: asset, identifier: AVMetadataIdentifier.commonIdentifierTitle)
    track.initialKey = getTagFilterByIdentifier(asset: asset, identifier: AVMetadataIdentifier.id3MetadataInitialKey)
    
    if let initialKey = getTagFilterByIdentifier(asset: asset, identifier: AVMetadataIdentifier.id3MetadataInitialKey) {
        track.initialKey = initialKey
    }
    
    let bpmStr = getTagFilterByIdentifier(asset: asset, identifier: AVMetadataIdentifier.id3MetadataBeatsPerMinute)
    if bpmStr != "" {
        track.bpm = Double(bpmStr!)!
    }
    
    return track
}

func formatDate(date: Date) -> String {
    let customFormatter = DateFormatter()
    customFormatter.dateFormat = "dd/MM/YY"
    return customFormatter.string(for: date)!
}
