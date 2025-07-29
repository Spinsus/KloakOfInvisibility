//
//  ShareViewController.swift
//  StripMetadata
//
//  Created by Kevo on 7/28/25.
//

import UIKit
import Social
import Photos
import UniformTypeIdentifiers

class ShareViewController: SLComposeServiceViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide the default compose interface
        self.view.isHidden = true
        
        // Show our custom info screen
        showInfoScreen()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Dismiss keyboard if it appears
        self.view.endEditing(true)
    }
    
    override func presentationAnimationDidFinish() {
        super.presentationAnimationDidFinish()
        
        // Force dismiss keyboard after presentation
        self.view.endEditing(true)
    }
    
    override func isContentValid() -> Bool {
        return true
    }
    
    override func didSelectPost() {
        // This won't be called since we're using custom interface
    }
    
    private func showInfoScreen() {
        let alert = UIAlertController(
            title: "🛡️ Strip Metadata", 
            message: "Creates a clean copy of your photo with private info removed:\n\n• GPS location\n• Camera details\n• Timestamps\n\nYour original photo stays unchanged. The clean copy is shared and then deleted automatically.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        })
        
        alert.addAction(UIAlertAction(title: "Continue", style: .default) { _ in
            // Process the shared photo
            guard let extensionContext = self.extensionContext,
                  let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
                self.showAlert(title: "Error", message: "No items to process")
                return
            }
            
            self.processSharedImages(inputItems)
        })
        
        present(alert, animated: true)
    }
    
    private func processSharedImages(_ inputItems: [NSExtensionItem]) {
        for inputItem in inputItems {
            guard let attachments = inputItem.attachments else { continue }
            
            for attachment in attachments {
                if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    
                    attachment.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] (item, error) in
                        guard let self = self, error == nil else { 
                            DispatchQueue.main.async {
                                self?.showAlert(title: "Error", message: "Failed to load image")
                            }
                            return 
                        }
                        
                        var imageData: Data?
                        
                        // Handle different input types
                        if let url = item as? URL {
                            imageData = try? Data(contentsOf: url)
                        } else if let data = item as? Data {
                            imageData = data
                        } else if let image = item as? UIImage {
                            imageData = image.jpegData(compressionQuality: 0.9)
                        }
                        
                        // Convert to clean JPEG (this strips most metadata)
                        if let originalData = imageData,
                           let originalImage = UIImage(data: originalData),
                           let cleanJpegData = originalImage.jpegData(compressionQuality: 0.9),
                           let cleanImage = UIImage(data: cleanJpegData) {
                            
                            DispatchQueue.main.async {
                                self.shareCleanImage(cleanImage)
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.showAlert(title: "Error", message: "Failed to process image")
                            }
                        }
                    }
                    return // Process first image only for now
                }
            }
        }
    }
    
    private func shareCleanImage(_ cleanImage: UIImage) {
        // Create a temporary file to share
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("clean_image_\(UUID().uuidString).jpg")
        
        guard let imageData = cleanImage.jpegData(compressionQuality: 0.9) else {
            showAlert(title: "Error", message: "Failed to create image data")
            return
        }
        
        do {
            try imageData.write(to: tempFile)
            
            // Create share sheet with the clean image
            let activityViewController = UIActivityViewController(activityItems: [tempFile], applicationActivities: nil)
            
            // Handle completion - delete temp file after sharing
            activityViewController.completionWithItemsHandler = { [weak self] (activityType, completed, returnedItems, error) in
                
                // Clean up temp file
                try? FileManager.default.removeItem(at: tempFile)
                
                // Complete the extension
                DispatchQueue.main.async {
                    if completed {
                        self?.showAlert(title: "✅ Success!", message: "Image shared with metadata removed!\n\nTemp file cleaned up automatically.")
                    } else {
                        self?.showAlert(title: "Share Cancelled", message: "No worries! Temp file was cleaned up.")
                    }
                }
            }
            
            // Present the share sheet
            present(activityViewController, animated: true)
            
        } catch {
            showAlert(title: "Error", message: "Failed to create temporary file: \(error.localizedDescription)")
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Done", style: .default) { _ in
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        })
        present(alert, animated: true)
    }
    
    override func configurationItems() -> [Any]! {
        return []
    }
}