import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

#if canImport(AppKit) && !canImport(UIKit)
extension NSColor {
    static var label: NSColor {
        return NSColor.labelColor
    }
}

typealias UIColor = NSColor

extension NSImage {
    func pngData() -> Data? {
        guard let tiffRepresentation = tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else {
            return nil
        }
        return bitmapImage.representation(using: .png, properties: [:])
    }
}

typealias UIImage = NSImage

extension Image {
    init(uiImage: NSImage) {
        self.init(nsImage: uiImage)
    }
}

enum UIKeyboardType {
    case `default`
    case asciiCapable
    case numbersAndPunctuation
    case URL
    case numberPad
    case phonePad
    case namePhonePad
    case emailAddress
    case decimalPad
    case twitter
    case webSearch
    case asciiCapableNumberPad
}

enum UINavigationBarTitleDisplayMode {
    case automatic
    case large
    case inline
}

extension View {
    func keyboardType(_ keyboardType: UIKeyboardType) -> some View {
        // On macOS, keyboard type is not applicable, so return self unchanged
        return self
    }

    func navigationBarTitleDisplayMode(_ displayMode: UINavigationBarTitleDisplayMode) -> some View {
        // On macOS, navigation bar title display mode is not applicable, so return self unchanged
        return self
    }
}

class UIPasteboard {
    static let general = UIPasteboard()

    var string: String? {
        get {
            return NSPasteboard.general.string(forType: .string)
        }
        set {
            NSPasteboard.general.clearContents()
            if let newValue = newValue {
                NSPasteboard.general.setString(newValue, forType: .string)
            }
        }
    }
}
#endif
