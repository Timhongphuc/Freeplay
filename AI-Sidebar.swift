//
//  AI-Sidebar.swift
//  Freeplay
//
//  Created by Tim Seufert on 26.10.25.
//

import SwiftUI

struct AI_Sidebar: View {
    var body: some View {
        NavigationSplitView(){
            if #available(macOS 26.0, *) {
                ChatView()
            } else {
                // Fallback on earlier versions
            }
        } detail: {
            ContentView()
        }.navigationSplitViewStyle(.automatic)
    }
}

#Preview {
    AI_Sidebar()
}
