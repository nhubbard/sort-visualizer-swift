//
//  CustomADSRWidget+UIKit.swift
//  Sort Symphony (iOS)
//
//  Created by Nicholas Hubbard on 4/3/23.
//

import Foundation
import SwiftUI
import AudioKitUI
import AudioKit

#if os(iOS)
@frozen public struct CustomADSRWidget: UIViewRepresentable {
  @AppStorage("synthAttack") var attack: Float = 0.5
  @AppStorage("synthDecay") var decay: Float = 0.5
  @AppStorage("synthSustain") var sustain: Float = 0.5
  @AppStorage("synthRelease") var release: Float = 0.5

  public typealias UIViewType = ADSRView
  var initialAttack: AUValue = 0.5
  var initialDecay: AUValue = 0.5
  var initialSustain: AUValue = 0.5
  var initialRelease: AUValue = 0.5
  let view: ADSRView!

  @MainActor
  public init(
    attack: AUValue = 0.5,
    decay: AUValue = 0.5,
    sustain: AUValue = 0.5,
    release: AUValue = 0.5
  ) {
    self.initialAttack = attack
    self.initialDecay = decay
    self.initialSustain = sustain
    self.initialRelease = release
    self.view = ADSRView()
  }

  public func makeUIView(context _: Context) -> ADSRView {
    view.attack = initialAttack
    view.decay = initialDecay
    view.sustain = initialSustain
    view.release = initialRelease
    view.callback = { newAttack, newDecay, newSustain, newRelease in
      self.attack = newAttack
      self.decay = newDecay
      self.sustain = newSustain
      self.release = newRelease
    }
    // view.bgColor = .systemGray2
    return view
  }

  public func updateUIView(_: ADSRView, context _: Context) {
    view.attack = attack
    view.decay = decay
    view.sustain = sustain
    view.release = release
  }
}
#endif
