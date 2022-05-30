//
//  UIImage+Extensions.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 5/27/22.
//

import Foundation
import AppKit
import SwiftUI

extension Image {
    static func ofAsset(_ named: String, _ size: CGFloat = CGFloat(16)) -> some View {
        return Image(named).resizable(capInsets: .init(), resizingMode: .stretch).frame(width: size, height: size)
    }
}
