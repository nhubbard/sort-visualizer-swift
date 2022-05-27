//
//  UIImage+Extensions.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/27/22.
//

import Foundation
import AppKit
import SwiftUI

extension Image {
    static func ofAsset(_ named: String) -> some View {
        return Image(named).resizable(capInsets: .init(), resizingMode: .stretch).frame(width: 16, height: 16)
    }
}
