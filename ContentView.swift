//
//  ContentView.swift
//  Freeplay
//
//  Created by Tim Seufert on 21.08.25.
//
//Beginning from Youtube Tutorial: https://www.youtube.com/watch?v=P0OdY9MVu_g.

import SwiftUI
import PencilKit
import AppKit
import Foundation
import PhotosUI
import FileProviderUI

struct Line { //Pretty similar to an GET/(POST) API CALL -> "line.lineWidth" ... parallels are there/given ;)
    var points = [CGPoint]()
    var color: Color = .blue
    var lineWidth: Double = 1.0
}

struct Shape: Identifiable {
    let id = UUID()
    var position = CGPoint(x:100 , y: 100)
    var color: Color = .blue
    var size: CGSize = CGSize(width: 170, height: 170)
    var type: ShapeType
    var text: String = "" // text content for .text shapes
    //var fontSize = 0.0 (Wait a minute...)
    var fontSize = 0.0
}

struct droppedText: Identifiable{
    let id = UUID()
    var position = CGPoint(x:100 ,y:100)
    var content: String = ""
}

struct droppedImage: Identifiable{
    let id = UUID()
    var position = CGPoint(x: 100, y: 100)
    var image: NSImage
}

enum Tools {
    case pencil
    case eraser
    case shapes
}

enum ShapeType {
    case circle
    case ellipse
    case rectangle
    case roundedRectangle
    case text //For the text feature for now. But I think I have to fix it later.
   // case triangle
}

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @State private var currentLine = Line() //Connection between "struct Line" and "struct ContentView"
    @State private var lines: [Line] = []

    @State private var currentShape = Shape(type: .rectangle) //Connection between "struct Shape" and "struct ContentView"
    @State private var shapes: [Shape] = []

    @State private var isPopover1Presented = false
    @State private var value = 1.0
    @State private var slider = 1.0

    @State private var isPopover2Presented = false

    @State private var currentColor: Color = .blue
    @State private var currentTool: Tools = .pencil

    @State private var showingAlert = false
    @State private var background = Image("Grid")

    @State private var lineWidthforEraser = 30.0
    @State private var checkEraserStatus: Bool = false

    @State private var amIdrawing: Bool = false

    @State private var currentShapeColor: Color = .blue
    @State private var isBlacktoggled: Bool = false
    @State private var isBluetoggled: Bool = false
    @State private var isGreentoggled: Bool = false
    @State private var isRedtoggled: Bool = false
    @State private var isYellowtoggled: Bool = false
    @State private var isOreangetoggled: Bool = false
    @State private var isWhitetoggled: Bool = false

   // @GestureState private var dragOffset: CGSize = .zero //AI helped me with this (It's a pretty specific use case I think personally... So it's hard to find the right answer for my problem via Google.)
    @State private var draggedShapeId: UUID?

    @State private var isPopover3Presented: Bool = false
    @State private var textsoncanvas: String = ""
   // @State private var fontSize: Double = 0  (Notes: Only make it a Double, if you wanna geet precision values.)
    //@State private var fontSize = 0.0 (This is now placed in: 'Shape.fontSize')
    @State private var fontSizeonCanvas = 0.0
    
    @State private var isPopover4Presented: Bool = false
    @State private var chosenPath: String = ""
    @State private var loadedImage: NSImage? = nil //Why? (18.10.2025, 2:40pm)
    @State private var presentImporter = false
    @State private var isTheImageloaded = false

    // Added for image position state: MADE BY AI LOL (But why? It also worked with the other objects)
    @State private var loadedImagePosition = CGPoint(x: 120, y: 120)
    @State private var imageBottle: [droppedImage] = []
    
    //FUNCTIONS:
    func render() -> URL {
        let renderer = ImageRenderer(content: CanvasExportView(lines: lines, shapes: shapes, imageBottle: imageBottle))
        let url = URL.documentsDirectory.appending(path: "Freeplay-Export.pdf")
        renderer.render  { size, context in
            var box = CGRect(origin: .zero, size: size)
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            pdf.beginPDFPage(nil)
            context(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
        }
        return url
    }

    var body: some View {
        ScrollView([.horizontal, .vertical]){
                ZStack {
                    
                    Canvas { context, size in
                        
                        for line in lines {
                            var path = Path()
                            path.addLines(line.points)
                            context.stroke(path, with: .color(line.color), lineWidth: line.lineWidth)
                        }
                        if !currentLine.points.isEmpty { //AI (Performance improvement)
                            var path = Path()
                            path.addLines(currentLine.points)
                            context.stroke(path, with: .color(currentLine.color), lineWidth: currentLine.lineWidth)
                        }
                        
                    }.gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                              
                        .onChanged({value in
                            let newPoint = value.location //Location inside the Window/Canvas
                            currentLine.points.append(newPoint)
                            //self.lines.append(currentLine)
                            currentLine.lineWidth = self.value
                            currentLine.color = self.currentColor
                            
                            if self.checkEraserStatus == true {
                                currentLine.lineWidth = lineWidthforEraser //Or currentLine.lineWidth = 7.0 (Let's see!)
                            } else if currentTool == .pencil {
                                self.value = 1.0
                                currentLine.lineWidth = self.slider
                                // NSCursor.crosshair
                            }
                        })
                            .onEnded ({ value in
                                self.lines.append(currentLine)
                                currentLine.lineWidth = self.value
                                self.currentLine = Line() //Important, so the new lines won't connect with the "old" lines.
                                currentLine.color = self.currentColor
                            })
                              
                    )
                    // .background(background)
                    
                    .dropDestination(for: String.self) { droppedShapes, location in //I moved it into the Canvas because
                        
                        guard let typeString = droppedShapes.first else { return false }
                        
                        let newShape: Shape
                        
                        if typeString == "circle" {
                            newShape = Shape(position: location, type: ShapeType.circle) //Is there a possibility for CGPoint?
                        } else if typeString == "ellipse" {
                            newShape = Shape(position: location, type: ShapeType.ellipse)
                        } else if typeString == "rectangle" {
                            newShape = Shape(position: location, type: ShapeType.rectangle)
                        } else if typeString == "rounded rectangle" {
                            newShape = Shape(position: location, type: ShapeType.roundedRectangle)
                        } else if typeString == "droptext" { //Text
                            newShape = Shape(position: location, type: ShapeType.text, text: textsoncanvas, fontSize: fontSizeonCanvas) //At this part, the Code passes the Text from "textoncanvas" to the Shape.text variable inside the Shape-Struct.
                        } else {
                            return false
                        }
                        
                        self.shapes.append(newShape)
                        
                        if typeString == "droptext" {
                            // reset the input after creating the text shape (Made by Xcode-AI)
                            self.textsoncanvas = ""
                        }
                        
                        return true
                    } //End DropDestination
                    
                    ForEach($shapes) { $shape in //Construction plan for every shape (If it works lol).
                        switch shape.type {
                        case .rectangle:
                            Rectangle()
                                .fill(shape.color)
                                .frame(width: shape.size.width, height: shape.size.height)
                                .position(shape.position)
                                .gesture(DragGesture()
                                    .onChanged { value in
                                        shape.position = value.location
                                    }
                                )
                        case .circle:
                            Circle()
                                .fill(shape.color)
                                .frame(width: shape.size.width, height: shape.size.height)
                                .position(shape.position)
                                .gesture(DragGesture()
                                    .onChanged { value in
                                        shape.position = value.location
                                    }
                                )
                        case .ellipse:
                            Ellipse()
                                .fill(shape.color)
                                .frame(width: shape.size.width + 100, height: shape.size.height)
                                .position(shape.position)
                                .gesture(DragGesture()
                                    .onChanged { value in
                                        shape.position = value.location
                                    }
                                )
                        case .roundedRectangle:
                            RoundedRectangle(cornerRadius: 20)
                                .fill(shape.color)
                                .frame(width: shape.size.width, height: shape.size.height)
                                .position(shape.position)
                                .gesture(DragGesture()
                                    .onChanged { value in
                                        shape.position = value.location
                                    }
                                )
                        case .text: // handle text shapes with model data (Changed by Xcode-AI)
                            Text(shape.text) //Changed from "textoncanvas, to shape.text" (Changed by Xcode-AI)
                                .font(.system(size: shape.fontSize, weight: .medium, design: .rounded))
                                .position(shape.position)
                                .gesture(DragGesture()
                                    .onChanged { value in
                                        shape.position = value.location
                                    }
                                )
                        }
                    }
                    
//                    if isTheImageloaded == true { //So let's see, if the position in the code works out well...(Spoiler: yes it does but there is much work left.)
//                        if let loadedImage {
//                            Image(nsImage: loadedImage)
//                                .resizable()
//                                .scaledToFit()
//                                .frame(width: 500, height: 700)
//                                .position(loadedImagePosition) // Use the state variable for position
//                                .gesture(DragGesture()
//                                    .onChanged { value in
//                                        loadedImagePosition = value.location // Update position
//                                    }
//                                )
//                        }
//                    } |´s
                    
                    ForEach($imageBottle) { $img in
                        Image(nsImage: img.image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 500, height: 700)
                            .position(img.position)
                            .shadow(radius: 10)
                            .gesture(DragGesture()
                                .onChanged { value in
                                    img.position = value.location
                                }
                            )
                    }
                    
                    
                } //ZStack Ending
                .frame(minWidth: 10000, minHeight: 10000)
                .padding()
                .toolbar {
                    
                    ToolbarItem(placement: .primaryAction) { //Key button to export the Canvas as a PDF. (Not fully finished yet: 03. Oct. 2025, 4:04pm)
                        ShareLink("Export", item: render())
                    }
                    
                    ToolbarItem(placement: .primaryAction) {
                        //Image(systemName: "trash.fill")
                        Button(){
                            showingAlert = true
                        } label: {
                            VStack{
                                Image(systemName: "trash.fill")
                            }
                            .alert("Are you sure? This action cannot be undone.", isPresented: $showingAlert){
                                Button("Cancel", role: .cancel) { }
                                Button("Go ahead", role: .destructive) {  self.lines.removeAll(); self.shapes.removeAll(); self.imageBottle.removeAll() } //Something I am pretty proud of...
                            }
                            
                        } .buttonStyle(.automatic)
                    }

                    
                    ToolbarItem(placement: .principal){
                        Button(action: {
                            isPopover1Presented.toggle()
                        }) {
                            VStack{
                                Image(systemName: "pencil.and.scribble")
                            }
                        }            .buttonStyle(.automatic)
                            .popover(isPresented: $isPopover1Presented, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
                                //Popover Draw
                                VStack{
                                    HStack{
                                        if colorScheme == .light{
                                            Button{
                                                currentColor = .black
                                                if currentColor == .black{
                                                    self.isBlacktoggled.toggle()
                                                    self.checkEraserStatus = false
                                                    currentLine.lineWidth = self.value
                                                    self.checkEraserStatus = false
                                                    self.currentTool = .pencil
                                                    
                                                    self.isGreentoggled = false
                                                    self.isBluetoggled = false
                                                    self.isRedtoggled = false
                                                    self.isYellowtoggled = false
                                                    self.isOreangetoggled = false
                                                } else {
                                                    self.isBlacktoggled = false
                                                }
                                            } label: {
                                                Text("")
                                                    .font(.headline)
                                                    .fontWeight(.semibold)
                                                    .padding(.vertical, 12)
                                                    .padding(.horizontal, 12)
                                                    .background(
                                                        Circle()
                                                            .fill(Color.black)
                                                    )
                                                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                                            }
                                            .buttonStyle(.plain)
                                            .overlay(
                                                isBlacktoggled ? Circle().stroke(Color.blue, lineWidth: 3)
                                                : nil
                                            )
                                        } else {
                                            Button{
                                                currentColor = .white
                                                if currentColor == .white{
                                                    self.isBlacktoggled.toggle()
                                                    self.checkEraserStatus = false
                                                    currentLine.lineWidth = self.value
                                                    self.checkEraserStatus = false
                                                    self.currentTool = .pencil
                                                    
                                                    self.isGreentoggled = false
                                                    self.isBluetoggled = false
                                                    self.isRedtoggled = false
                                                    self.isYellowtoggled = false
                                                    self.isOreangetoggled = false
                                                    self.isBlacktoggled = false
                                                } else {
                                                    self.isWhitetoggled = false
                                                }
                                            } label: {
                                                Text("")
                                                    .font(.headline)
                                                    .fontWeight(.semibold)
                                                    .padding(.vertical, 12)
                                                    .padding(.horizontal, 12)
                                                    .background(
                                                        Circle()
                                                            .fill(Color.white)
                                                    )
                                                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                                            }
                                            .buttonStyle(.plain)
                                            .overlay(
                                                isWhitetoggled ? Circle().stroke(Color.blue, lineWidth: 3)
                                                : nil
                                            )
                                        }
                                        
                                        Button{
                                            currentColor = .blue
                                            if currentColor == .blue{
                                                self.isBluetoggled.toggle()
                                                self.checkEraserStatus = false
                                                self.currentTool = .pencil
                                                
                                                self.isGreentoggled = false
                                                self.isRedtoggled = false
                                                self.isYellowtoggled = false
                                                self.isOreangetoggled = false
                                                self.isWhitetoggled = false
                                                self.isBlacktoggled = false
                                            } else {
                                                self.isBluetoggled = false
                                            }
                                        } label: {
                                            Text("")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                                .padding(.vertical, 12)
                                                .padding(.horizontal, 12)
                                                .background(
                                                    Circle()
                                                        .fill(Color.blue)
                                                )
                                                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                                        } .buttonStyle(.plain)
                                            .overlay(
                                                isBluetoggled ? Circle().stroke(Color.blue, lineWidth: 3) : nil
                                            )
                                        
                                        Button{
                                            currentColor = .green
                                            if currentColor == .green{
                                                self.isGreentoggled.toggle()
                                                self.checkEraserStatus = false
                                                self.currentTool = .pencil
                                                
                                                self.isBluetoggled = false
                                                self.isRedtoggled = false
                                                self.isYellowtoggled = false
                                                self.isOreangetoggled = false
                                                self.isWhitetoggled = false
                                                self.isBlacktoggled = false
                                            } else {
                                                self.isGreentoggled = false
                                            }
                                        } label: {
                                            Text("")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                                .padding(.vertical, 12)
                                                .padding(.horizontal, 12)
                                                .background(
                                                    Circle()
                                                        .fill(Color.green)
                                                )
                                                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                                        }
                                        .buttonStyle(.plain)
                                        .overlay(
                                            isGreentoggled ? Circle().stroke(Color.blue, lineWidth: 3) : nil
                                        )
                                        
                                        Button{
                                            currentColor = .red
                                            if currentColor == .red{
                                                self.isRedtoggled.toggle()
                                                self.checkEraserStatus = false
                                                self.currentTool = .pencil
                                                
                                                self.isGreentoggled = false
                                                self.isBluetoggled = false
                                                self.isYellowtoggled = false
                                                self.isOreangetoggled = false
                                                self.isWhitetoggled = false
                                                self.isBlacktoggled = false
                                            } else {
                                                self.isRedtoggled = false
                                            }
                                        } label: {
                                            Text("")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                                .padding(.vertical, 12)
                                                .padding(.horizontal, 12)
                                                .background(
                                                    Circle()
                                                        .fill(Color.red)
                                                )
                                                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                                        }
                                        .buttonStyle(.plain)
                                        .overlay(
                                            isRedtoggled ? Circle().stroke(Color.blue, lineWidth: 3) : nil
                                        )
                                        
                                        Button{
                                            currentColor = .yellow
                                            if currentColor == .yellow{
                                                self.isYellowtoggled.toggle()
                                                self.checkEraserStatus = false
                                                self.currentTool = .pencil
                                                
                                                self.isGreentoggled = false
                                                self.isBluetoggled = false
                                                self.isRedtoggled = false
                                                self.isOreangetoggled = false
                                                self.isWhitetoggled = false
                                                self.isBlacktoggled = false
                                            } else {
                                                self.isYellowtoggled = false
                                            }
                                        } label: {
                                            Text("")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                                .padding(.vertical, 12)
                                                .padding(.horizontal, 12)
                                                .background(
                                                    Circle()
                                                        .fill(Color.yellow)
                                                )
                                                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                                        }
                                        .buttonStyle(.plain)
                                        .overlay(
                                            isYellowtoggled ? Circle().stroke(Color.blue, lineWidth: 3) : nil
                                        )
                                        
                                        Button{
                                            currentColor = .orange
                                            if currentColor == .orange{
                                                self.isOreangetoggled.toggle()
                                                self.checkEraserStatus = false
                                                currentLine.lineWidth = self.value
                                                self.checkEraserStatus = false
                                                self.currentTool = .pencil
                                                
                                                self.isGreentoggled = false
                                                self.isBluetoggled = false
                                                self.isRedtoggled = false
                                                self.isYellowtoggled = false
                                                self.isWhitetoggled = false
                                                self.isBlacktoggled = false
                                            } else {
                                                self.isOreangetoggled = false
                                            }
                                        } label: {
                                            Text("")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                                .padding(.vertical, 12)
                                                .padding(.horizontal, 12)
                                                .background(
                                                    Circle()
                                                        .fill(Color.orange)
                                                )
                                                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                                        }
                                        .buttonStyle(.plain)
                                        .overlay(
                                            isOreangetoggled ? Circle().stroke(Color.blue, lineWidth: 3)
                                            : nil
                                        )
                                        
                                        Button{
                                            currentColor = Color("Eraser Color")
                                            currentLine.lineWidth = self.lineWidthforEraser
                                            self.checkEraserStatus.toggle()
                                            
                                            self.isGreentoggled = false
                                            self.isBluetoggled = false
                                            self.isRedtoggled = false
                                            self.isYellowtoggled = false
                                            self.isOreangetoggled = false
                                            self.isWhitetoggled = false
                                            self.isBlacktoggled = false
                                        } label: {
                                            Text("")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                                .padding(.vertical, 12)
                                                .padding(.horizontal, 12)
                                                .background(
                                                    Image(systemName: "eraser.fill")
                                                )
                                                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                                        }
                                        .buttonStyle(.plain)
                                        .overlay(
                                            checkEraserStatus ? Circle().stroke(Color.red, lineWidth: 3)
                                            : nil
                                        )
                                    }
                                    
                                    //Spacer()
                                    Text("Line Width")
                                        .padding(.bottom, -10)
                                        .font(.system(size: 12, weight: .medium))
                                    Slider(value: $slider, in: 1.0...100.0, onEditingChanged: { _ in currentLine.lineWidth = slider}) //AI helped me there. //I've done it wrong all the time. I thought this way -> "self.lines.lineWidth" but I've forgotten that there is also the @State variable, which gives me access to the "line.lineWidth" path.
                                        .padding()
                                    
                                    Text("Current line width: \(slider)")
                                    
                                } .frame(width: 300, height: 140)
                                //END
                            }
                    }
                    
                    //Popover 2 beginning
                    ToolbarItem(placement: .principal) {
                        Button(action: {
                            isPopover2Presented.toggle()
                        }) {
                            VStack{
                                Image(systemName: "capsule.on.rectangle.fill")
                            }
                        }            .buttonStyle(.automatic)
                            .popover(isPresented: $isPopover2Presented, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
                                
                                VStack {
                                    HStack{
                                        Circle()
                                            .padding(20)
                                            .scaledToFit()
                                            .draggable("circle")
                                        Ellipse()
                                            .padding(.top, 50)
                                            .padding(.bottom, 30)
                                            .padding(.horizontal, 30)
                                            .draggable("ellipse")
                                    } .padding(1)
                                    
                                    HStack{
                                        Rectangle()
                                            .padding(20)
                                            .scaledToFit()
                                            .draggable("rectangle")
                                        RoundedRectangle(cornerRadius: 20)
                                            .padding(20)
                                            .scaledToFit()
                                            .draggable("rounded rectangle")
                                    }
                                    
                                } .frame(width: 300, height: 300)
                            }
                    } //Toolbar element (item) shapes collection preview ending...
                    
                    ToolbarItem(placement: .principal){
                        Button(action: {
                            isPopover3Presented.toggle()
                        }) {
                            VStack{
                                Image(systemName: "character.cursor.ibeam")
                            }
                        } .buttonStyle(.automatic)
                            .popover(isPresented: $isPopover3Presented, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
                                VStack{
                                    
                                    TextField("Enter your text here...", text: $textsoncanvas)
                                        .padding(20)
                                    
                                    Slider(value: $fontSizeonCanvas, in: 10.0...50.0, step: 1.0)
                                        .padding(.horizontal, 10)
                                    Text("Font size: \(fontSizeonCanvas)")
                                    
                                    if colorScheme == .light {
                                        Text(self.textsoncanvas)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .multilineTextAlignment(.center)
                                            .padding()
                                            .frame(width: 270, height: 170)
                                            .background(Rectangle().fill(Color.white).shadow(radius: 4).cornerRadius(20))
                                            .draggable("droptext")
                                    } else {
                                        Text(self.textsoncanvas)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .multilineTextAlignment(.center)
                                            .padding()
                                            .frame(width: 270, height: 170)
                                            .background(Rectangle().fill(Color.black).shadow(radius: 4).cornerRadius(20))
                                            .draggable("droptext")
                                    }
                                    
                                } .frame(width: 300, height:300)
                            }
                        
                    }
                    
                    ToolbarItem(placement: .principal){
                        Button(action: {
                            isPopover4Presented.toggle()
                        }) {
                            VStack{
                                Image(systemName: "photo.fill")
                            }
                        }.buttonStyle(.automatic)
                        
                            .popover(isPresented: $isPopover4Presented, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom){
                                VStack{
                                    Button(action: { presentImporter = true }) {
                                        Text("Browse your images...")
                                            .foregroundStyle(Color.white)
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 40)
                                            .background(
                                            Rectangle()
                                                .fill(Color.blue)
                                                .cornerRadius(7)
                                            )
                                            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                                        
                                    }
                                    // *** Hier ist die Änderung! *** (XCODE AI)
                                    .fileImporter(isPresented: $presentImporter, allowedContentTypes: [.png, .jpeg]) { result in
                                        switch result {
                                        case .success(let url):
                                            print(url)
                                            if url.startAccessingSecurityScopedResource() {
                                                if let image = NSImage(contentsOf: url) {
                                                    loadedImage = image
                                                    isTheImageloaded = true
                                                    self.imageBottle.append(droppedImage(image: image))
                                                }
                                                url.stopAccessingSecurityScopedResource()
                                            }
                                        case .failure(let error):
                                            print(error)
                                        }
                                    }
                                    .buttonStyle(.borderless)
                                }.frame(width: 250, height: 70)
                            }
                    }
                    
                    
                }.frame(width: 10000, height: 10000)
            }
        }
 }

#Preview {
    ContentView()
 }

//EXPERIMENTAL (Tool for Export!)
        struct CanvasExportView: View {  //AI helped me here...
            var lines: [Line]
            var shapes: [Shape]
            var imageBottle: [droppedImage]
            
            //@State private var imageBottle: [droppedImage] = []
            
            var body: some View { //Every element(s) out of the Canvas had to get exported.
                ZStack {
                    Canvas { context, size in
                        for line in lines {
                            var path = Path()
                            path.addLines(line.points)
                            context.stroke(path, with: .color(line.color), lineWidth: line.lineWidth)
                        }
                    }
                    ForEach(shapes) { shape in
                        switch shape.type {
                        case .rectangle:
                            Rectangle()
                                .fill(shape.color)
                                .frame(width: shape.size.width, height: shape.size.height)
                                .position(shape.position)
                        case .circle:
                            Circle()
                                .fill(shape.color)
                                .frame(width: shape.size.width, height: shape.size.height)
                                .position(shape.position)
                        case .ellipse:
                            Ellipse()
                                .fill(shape.color)
                                .frame(width: shape.size.width + 100, height: shape.size.height)
                                .position(shape.position)
                        case .roundedRectangle:
                            RoundedRectangle(cornerRadius: 20)
                                .fill(shape.color)
                                .frame(width: shape.size.width, height: shape.size.height)
                                .position(shape.position)
                        case .text:
                            Text(shape.text)
                                .font(.system(size: shape.fontSize, weight: .medium, design: .rounded))
                                .position(shape.position)
                        }
                    }
                    
                    ForEach(imageBottle) { img in
                        Image(nsImage: img.image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 500, height: 700)
                            .position(img.position)
                    }
                }
                .frame(width: 10000, height: 10000)
                .padding()
            }
        }

