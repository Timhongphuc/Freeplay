//
//  TestView.swift
//  Freeplay
//
//  Created by Tim Seufert on 19.10.25.
//  From: https://stackoverflow.com/questions/68885275/how-can-i-grab-a-pdf-file-from-the-files-app-in-swiftui-and-import-it-into-my-ap
//  With help of Apple Intelligence

import SwiftUI

struct TestView : View {
    @State private var presentImporter = false
    @State private var loadedImage: NSImage? = nil    // Korrekte Initialisierung

    var body: some View {
        VStack {
            Button("Open") {
                presentImporter = true
            }
            .fileImporter(isPresented: $presentImporter, allowedContentTypes: [.png, .jpeg]) { result in
                switch result {
                case .success(let url):
                    print(url)
                    if url.startAccessingSecurityScopedResource() {
                        if let image = NSImage(contentsOf: url) {
                            loadedImage = image
                        }
                        url.stopAccessingSecurityScopedResource()
                    }
                case .failure(let error):
                    print(error)
                }
            }

            if let loadedImage {
                Image(nsImage: loadedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
            }

           // Text("Hello World!")
             //   .padding(20)
        }
        .padding()
    }
}

#Preview {
    TestView()
}
