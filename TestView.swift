//
//  TestView.swift
//  Freeplay
//
//  Created by Tim Seufert on 19.10.25.
//  From: https://stackoverflow.com/questions/68885275/how-can-i-grab-a-pdf-file-from-the-files-app-in-swiftui-and-import-it-into-my-ap

import SwiftUI

struct TestView : View {
    @State private var presentImporter = false
    
    var body: some View {
        Button("Open") {
            presentImporter = true
        }.fileImporter(isPresented: $presentImporter, allowedContentTypes: [.png, .jpeg]) { result in
            switch result {
            case .success(let url):
                print(url)
                //use `url.startAccessingSecurityScopedResource()` if you are going to read the data
            case .failure(let error):
                print(error)
            }
        }
    }
}


#Preview {
    TestView()
}
