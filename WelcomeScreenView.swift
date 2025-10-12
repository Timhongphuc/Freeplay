//
//  WelcomeScreenView.swift
//  Freeplay
//
//  Created by Tim Seufert on 26.09.25.
//

import SwiftUI

struct WelcomeScreenView: View {
    var body: some View {
        NavigationStack{
            Spacer(minLength: 200)
            HStack{
                Text("Welcome back to")
                    .font(Font.largeTitle.bold())
                Text("Freeplay!")
                    .font(Font.largeTitle.bold())
                    .foregroundStyle(
                        LinearGradient(colors: [.blue, .purple], startPoint:
                                .topLeading, endPoint: .bottomTrailing
                        )
                    )
            } //.padding(.top, 200) //HStack End
            
            HStack{
                NavigationLink{
                    ContentView()
                } label: {
                    Text("+ Start creating")
                        .font(.system(size: 12, weight: .semibold))
                    //                    .background(Color.blue)
                }
            
            Button{
                NSApplication.shared.terminate(nil)
            } label: {
                //Image(systemName: "power.circle.fill")
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Quit Freeplay")
                    .font(.system(size: 12, weight: .semibold))
            }
            }
            
            VStack{
                Text("Freeplay Stable Alpha 1.35, Build 276")
                    .font(Font.caption.bold())
                    .foregroundStyle(Color.gray)
                
                Spacer()
                
                Text("The Freeplay Project is open source at: https://github.com/Timhongphuc/Freeplay")
                    .font(Font.caption.bold())
            }
        } //.frame(width: 500, height: 300)
    }
}

#Preview {
    WelcomeScreenView()
}
