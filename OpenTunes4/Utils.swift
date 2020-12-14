import Foundation
import AVFoundation
import SwiftUI
import CoreData


let IMPORT_DATE_KEY = "opentunes.import_date"

private func mapGEOB(_ attrs: [AVMetadataExtraAttributeKey : Any]) -> (key: String?, value: String?) {
    for (k, v) in attrs {
        let key = k.rawValue
        let aValue = String(describing: v)
        
//        print("Key: \(key), Value: \(aValue)")
        
        if aValue == "opentunes.import_date" {
            return ("key", aValue)
        }
    }
    return ("", "")
}

func getGeobByKey(asset: AVAsset) -> Date? {
    let items = AVMetadataItem.metadataItems(from: asset.metadata, filteredByIdentifier: AVMetadataIdentifier.id3MetadataGeneralEncapsulatedObject)
    
    for item in items {
        guard let extraAttributes = item.extraAttributes else {
            return nil
        }
        let info : AVMetadataExtraAttributeKey = AVMetadataExtraAttributeKey(rawValue: "info")
        let decodedStr = String(data: item.value as! Data, encoding: .utf8)!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: decodedStr)
        
        guard let extraInfo = extraAttributes[info] else {
            return nil
        }
        if extraInfo as! String == "opentunes.import_date" {
            return date
        }
    }
    return nil
}

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

func getGeobTag(asset: AVAsset) {
    let items = AVMetadataItem.metadataItems(from: asset.metadata, filteredByIdentifier: AVMetadataIdentifier.id3MetadataGeneralEncapsulatedObject)
    
    for item in items {
        let decodedString = String(data: item.value as! Data, encoding: .utf8)!
//        let dateFormatter = DateFormatter()
        print(decodedString)
//        dateFormatter.dateFormat = "yyyy-MM-dd"
//        let date = dateFormatter.date(from: decodedString)!
//        print(date)
    }
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
    track.dateAdded = getGeobByKey(asset: asset)
    
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
    customFormatter.dateFormat = "YY/MM/dd"
    return customFormatter.string(for: date)!
}

func fileDateAdded(url: URL) -> Date {
    let attr = try! FileManager.default.attributesOfItem(atPath: url.path)
    let dateAdded = attr[FileAttributeKey.creationDate] as? Date
    return dateAdded!
}
