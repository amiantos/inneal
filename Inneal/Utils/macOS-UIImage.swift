//
//  macOS-UIImage.swift
//  Inneal
//
//  Created by Brad Root on 5/30/24.
//

#if os(macOS)
import Cocoa

// Step 1: Typealias UIImage to NSImage
typealias UIImage = NSImage

// Step 2: You might want to add these APIs that UIImage has but NSImage doesn't.
extension NSImage {
    var cgImage: CGImage? {
        var proposedRect = CGRect(origin: .zero, size: size)

        return cgImage(forProposedRect: &proposedRect,
                       context: nil,
                       hints: nil)
    }

    convenience init?(named name: String) {
        self.init(named: name)
    }

    func pngData() -> Data? {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let bitmapRepresentation = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRepresentation.representation(using: .png, properties: [:])
    }
}
#endif

