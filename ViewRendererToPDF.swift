//
//  ViewRendererToPDF.swift
//  Freeplay
//
//  Created by Tim Seufert on 03.10.25.
// From Tutorial "Hacking with Swift; Paul Hudson: https://www.hackingwithswift.com/quick-start/swiftui/how-to-render-a-swiftui-view-to-a-pdf"

import SwiftUI

struct ViewRendererToPDF: View {
    var body: some View {
        ShareLink("Export PDF", item: render())
    }
    
func render() -> URL {
        
//    let renderer = ImageRenderer(content:
//        Text("Hello, World!")
//            .font(.largeTitle)
//            .foregroundStyle(.white)
//            .padding()
//            .background(.blue)
//            .clipShape(Capsule())
//        )
    
    let renderer = ImageRenderer(content:
        Text("The Freeplay Project is open souce at: https://github.com/Timhongphuc/Freeplay")
        )
    
    let url = URL.documentsDirectory.appending(path: "FreeplayCanvasOutput.pdf")
    
    renderer.render  { size, context in
        var box = CGRect(x:0,y:0, width: size.width, height: size.height)
        
        guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else {
            return
        }
        
        pdf.beginPDFPage(nil)
        
        context(pdf)
        
        pdf.endPDFPage()
        pdf.closePDF()
        }
    return url
    }
}

#Preview {
    ViewRendererToPDF()
}
