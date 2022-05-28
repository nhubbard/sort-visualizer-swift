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
        }.commands {
            SidebarCommands()
        }
    }
}
