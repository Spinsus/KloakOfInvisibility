//
//  MetadataStripper.swift
//  StripMetadata
//
//  Created by Kevo on 7/28/25.
//

import Foundation
import UIKit
import ImageIO
import AVFoundation
import MobileCoreServices
import UniformTypeIdentifiers

class MetadataStripper {
    
    static func stripMetadata(from imageData: Data) -> Data? {
        print("🔧 MetadataStripper: Starting with \(imageData.count) bytes")
        
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            print("❌ MetadataStripper: Failed to create CGImageSource")
            return nil
        }
        
        let sourceType = CGImageSourceGetType(source)
        print("🔧 MetadataStripper: Source type: \(sourceType as String? ?? "unknown")")
        
        guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            print("❌ MetadataStripper: Failed to create CGImage")
            return nil
        }
        
        print("🔧 MetadataStripper: Successfully created CGImage")
        
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
            print("❌ MetadataStripper: Failed to create CGImageDestination")
            return nil
        }
        
        // Completely clean properties - no metadata at all
        let cleanProperties: [CFString: Any] = [:]
        
        CGImageDestinationAddImage(destination, cgImage, cleanProperties as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            print("❌ MetadataStripper: Failed to finalize destination")
            return nil
        }
        
        print("✅ MetadataStripper: Success! Output: \(data.count) bytes")
        return data as Data
    }
    
    static func stripMetadata(from image: UIImage, quality: CGFloat = 0.9) -> Data? {
        guard let imageData = image.jpegData(compressionQuality: quality) else {
            return nil
        }
        
        return stripMetadata(from: imageData)
    }
    
    static func stripVideoMetadata(from url: URL, completion: @escaping (URL?) -> Void) {
        let asset = AVURLAsset(url: url)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            completion(nil)
            return
        }
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let outputURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.metadata = []
        exportSession.metadataItemFilter = AVMetadataItemFilter.forSharing()
        
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                if exportSession.status == .completed {
                    completion(outputURL)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    static func getCleanFilename(from originalURL: URL) -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileExtension = originalURL.pathExtension.lowercased()
        
        switch fileExtension {
        case "jpg", "jpeg":
            return "image_\(timestamp).jpg"
        case "png":
            return "image_\(timestamp).png"
        case "heic":
            return "image_\(timestamp).jpg"
        case "mp4", "mov":
            return "video_\(timestamp).mp4"
        default:
            return "media_\(timestamp).\(fileExtension)"
        }
    }
    
    static func createTemporaryCleanFile(from data: Data, withName filename: String) -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempURL = tempDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Error writing temporary file: \(error)")
            return nil
        }
    }
    
    static func cleanupTemporaryFile(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}