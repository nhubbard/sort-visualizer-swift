//
//  Sort2App.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 4/26/22.
//
//  References:
//    1. https://sarunw.com/posts/how-to-toggle-sidebar-in-macos/

import SwiftUI

@main
struct Sort2App: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
        .frame(minWidth: 1400, minHeight: 900)
        .padding(.all, 2)
        .task {
          // Create default settings
          if !UserDefaults.standard.bool(forKey: "isConfigured") {
            UserDefaults.standard.setValue(36, forKey: "synthLowNote")
            UserDefaults.standard.setValue(72, forKey: "synthHighNote")
            UserDefaults.standard.setValue(0.5, forKey: "synthAmplitude")
            UserDefaults.standard.setValue(0.5, forKey: "synthAttack")
            UserDefaults.standard.setValue(0.5, forKey: "synthDecay")
            UserDefaults.standard.setValue(0.5, forKey: "synthSustain")
            UserDefaults.standard.setValue(0.5, forKey: "synthRelease")
            UserDefaults.standard.setValue(false, forKey: "sortSoundOn")
            UserDefaults.standard.setValue(0.1, forKey: "sortDelay")
            UserDefaults.standard.setValue(256, forKey: "sortArraySize")
            UserDefaults.standard.setValue(false, forKey: "sortFormatRuntime")
            UserDefaults.standard.setValue(0, forKey: "sortShuffleMethod")
            UserDefaults.standard.setValue(0, forKey: "sortCodeViewTheme")
            UserDefaults.standard.setValue(true, forKey: "warnBogoSort")
            UserDefaults.standard.setValue(true, forKey: "warnBitonicSort")
            UserDefaults.standard.setValue(true, forKey: "isConfigured")
          }
        }
    }
    #if targetEnvironment(macCatalyst)
    .commands {
      SidebarCommands()
    }
    .windowResizability(.contentMinSize)
    #endif
  }
}
