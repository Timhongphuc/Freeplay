//
//  FreeplayApp.swift
//  Freeplay
//
//  Created by Tim Seufert on 21.08.25.
//

import SwiftUI

@main
struct FreeplayApp: App {
    var body: some Scene {
        WindowGroup {
            if #available(macOS 26.0, *) {
                WelcomeScreenView()
            } else {
                // Fallback on earlier versions
            }
        }
    }
}
