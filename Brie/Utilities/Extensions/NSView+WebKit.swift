import AppKit
import WebKit

extension WKWebView {
    func saveSnapshot() -> Data? {
        guard let cgImage = try? self.takeSnapshot(configuration: nil) else {
            return nil
        }
        
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: .png, properties: [:])
    }
    
    func takeSnapshot(configuration: WKSnapshotConfiguration?) throws -> CGImage {
        var snapshotImage: CGImage?
        var snapshotError: Error?
        let semaphore = DispatchSemaphore(value: 0)
        
        self.takeSnapshot(with: configuration) { image, error in
            if let image = image {
                let imageRep = NSBitmapImageRep(data: image.tiffRepresentation!)
                snapshotImage = imageRep?.cgImage
            }
            snapshotError = error
            semaphore.signal()
        }
        
        semaphore.wait()
        
        if let error = snapshotError {
            throw error
        }
        
        guard let image = snapshotImage else {
            throw NSError(domain: "WebViewSnapshot", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to capture snapshot"])
        }
        
        return image
    }
}

