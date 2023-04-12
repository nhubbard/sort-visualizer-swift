//
//  CustomADSRWidget+AppKit.swift
//  Sort Visualizer (iOS)
//
//  Created by Nicholas Hubbard on 4/3/23.
//

import Foundation
import SwiftUI
import AudioKitUI
import AudioKit

#if os(macOS)
@frozen public struct CustomADSRWidget: NSViewRepresentable {
  @AppStorage("synthAttack") var attack: Float = 0.5
  @AppStorage("synthDecay") var decay: Float = 0.5
  @AppStorage("synthSustain") var sustain: Float = 0.5
  @AppStorage("synthRelease") var release: Float = 0.5

  public typealias NSViewType = ADSRView
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
    self.view = ADSRView(coder: NSCoder())
  }

  public func makeNSView(context _: Context) -> ADSRView {
    view.attackDuration = initialAttack
    view.decayDuration = initialDecay
    view.sustainLevel = initialSustain
    view.releaseDuration = initialRelease
    view.callback = { newAttack, newDecay, newSustain, newRelease in
      self.attack = newAttack
      self.decay = newDecay
      self.sustain = newSustain
      self.release = newRelease
    }
    // view.bgColor = .systemGray2
    return view
  }

  public func updateNSView(_: ADSRView, context _: Context) {
    view.attackDuration = attack
    view.decayDuration = decay
    view.sustainLevel = sustain
    view.releaseDuration = release
  }
}
#endif
