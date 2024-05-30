//
//  InnealImage.swift
//  Inneal
//
//  Created by Brad Root on 5/30/24.
//

import SwiftUI

#if os(iOS)
import UIKit
public typealias InnealImage = UIImage
#elseif os(macOS)
import AppKit
public typealias InnealImage = NSImage
#endif

extension InnealImage {
    var swiftUIImage: Image {
        Image(innealImage: self)
    }
}

extension Image {
    init(innealImage: InnealImage) {
        #if os(iOS)
        self.init(uiImage: innealImage)
        #elseif os(macOS)
        self.init(nsImage: innealImage)
        #endif
    }
}
