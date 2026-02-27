import AppKit
import CryptoKit

extension Data {
    var sha256Hash: String {
        let digest = SHA256.hash(data: self)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

extension NSImage {
    func resized(maxDimension: CGFloat) -> NSImage {
        let currentSize = self.size
        guard currentSize.width > 0, currentSize.height > 0 else { return self }

        let scale: CGFloat
        if currentSize.width > currentSize.height {
            scale = maxDimension / currentSize.width
        } else {
            scale = maxDimension / currentSize.height
        }

        guard scale < 1.0 else { return self }

        let newSize = NSSize(
            width: currentSize.width * scale,
            height: currentSize.height * scale
        )

        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        self.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: currentSize),
            operation: .copy,
            fraction: 1.0
        )
        newImage.unlockFocus()
        return newImage
    }

    var pngData: Data? {
        guard let tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffRepresentation)
        else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}

extension Date {
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
