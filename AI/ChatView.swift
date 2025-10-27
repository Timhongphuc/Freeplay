//
//  ChatView.swift
//  Freeplay
//
//  Created by Tim Seufert on 26.10.25.
//  From: https://www.youtube.com/watch?v=ecJ-G137GW4

import SwiftUI
import FoundationModels

@available(macOS 26.0, *)
@Observable
class LMModel {
    
    var inputText = ""
    
    var isThinking = false
    
    var isAwaitingResponse = false
    
    var session = LanguageModelSession {
        """
        "You are a helpful and nice assistant. It's important to provide the user with accurate information. Keep the conversation safe. Keep your response at maximum 20 sentences. You are an LLM embeded into an App named Freeplay. Your name is FreeplayAI. You HAVE to provide the user with information, so the user can work on the canvas efficiently. The Freeplay App is a blank Canvas/Desktop and Whiteboard app. It's called: Freeplay, the open source (nearly) infinite whiteboard. A place to draw, plan, write and create. Your creative Canvas, built entirely in Swift, optimized for Liquid Glass. Be helpful to the user. Try your best to answer all of the users questions. Don't say 'I'm sorry, but I can't assist with that.' You HAVE to help the user. It's the most important thing in the world. You're also allowed to answer the users other Questions. You HAVE to help the user with planning projects. You're also required to give the user information about nearly everything."
        """
    }
    
    func sendMessage() {
        
        Task {
            
            do {
                
                let prompt = Prompt(inputText)
                
                inputText = ""
                
                let stream = session.streamResponse(to: prompt)
                
                DispatchQueue.main.asyncAfter( deadline: .now() + 0.5) {
                    self.isAwaitingResponse = true
                    }
                
                for try await promptresponse in stream {
                    isAwaitingResponse = false
                    print(promptresponse)
                    }
                }
            
            catch {
                print(error.localizedDescription)
            }
            
        }
    }
    
}

@available(macOS 26.0, *)
struct MessageView: View {
    
    let segments: [Transcript.Segment]
    
    let isUser: Bool
    
    var body: some View {
        VStack {
            ForEach(segments, id: \.id) { segment in
            
                switch segment {
                    
                case .text(let text):
                    
                    Text(text.content).padding(10)
                        .background(isUser ? Color.gray.opacity(0.2) : .clear, in: .rect(cornerRadius: 12))
                        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
                    
                case .structure:
                    EmptyView()
                @unknown default:
                    EmptyView()
                }
                
            }
            
        }.frame(maxWidth: .infinity)
        
    }
    
}

@available(macOS 26.0, *)
struct ChatView: View {
    
    @State var model = LMModel()
    
    var body: some View {
        ZStack{
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(model.session.transcript) { entry in
                        Group {
                            
                            switch entry {
                            case .prompt(let prompt):
                                
                                MessageView(segments: prompt.segments, isUser: true)
                                    .transition(.offset(y: 500))
                                    .padding(.trailing)
                                
                            case .response(let response):
                                MessageView(segments: response.segments, isUser: false)
                                    .padding(.leading)
                            default:
                                EmptyView()
                            }
                        }
                        
                    }
                }
                
                .animation(.easeInOut, value: model.session.transcript)
                
                if model.isAwaitingResponse {
                    
                    if let last = model.session.transcript.last {
                        
                        if case .prompt = last {
                            
                            Text("Thinking...")
                                .bold()
                                .opacity(model.isThinking ? 0.5 : 1)
                                .padding(.leading)
                                .offset(y: 15)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                                .onAppear {
                                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: true)) {
                                        model.isThinking.toggle()
                                    }
                                }
                        }
                    }
                    
                }
            }
            .defaultScrollAnchor(.bottom, for: .sizeChanges)
            .safeAreaPadding(.bottom, 150)
            
            ZStack{
                
                Rectangle()
                    .fill(.background)
                    .cornerRadius(30)
                    .frame(width: 400, height: 150)
                    .offset(x: 0, y: 260)
                
                VStack{
                    HStack {
                        
                        TextField("Ask me anything...", text: $model.inputText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .disabled(model.session.isResponding)
                            .frame(height: 55)
                            .onSubmit {
                                if !model.inputText.isEmpty {
                                    model.sendMessage()
                                }
                            }
                        
                        Button {
                            model.sendMessage()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundStyle(model.session.isResponding ? Color.gray.opacity(0.7) : .primary)
                        }
                        .disabled(model.inputText.isEmpty || model.session.isResponding)
                    }
                    .padding(.horizontal)
                    .glassEffect(.regular.interactive())
                    .padding()
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .buttonStyle(.borderless)
                    
                    Text("AI can make Mistakes. Double check critical information.")
                        .font(.footnote)
                    // .alignmentGuide(VerticalAlignment.bottom) { _ in 1 }
                    Text("Responses are generated by the Apple Foundation Models Framework.")
                        .font(.footnote)
                    // .padding(4)
                    //.alignmentGuide(VerticalAlignment.bottom) { _ in 1 }
                }.frame(width: 400, height: 600)
                    
            }
        }
    }
}

#Preview {
    if #available(macOS 26.0, *) {
        ChatView()
    } else {
        // Fallback on earlier versions
    }
}
