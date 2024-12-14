//
//  draw.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 5/12/24.
//
// CanvasView.swift
import SwiftUI
import PencilKit
import Vision




import SwiftUI
import PencilKit
import Vision

struct CanvasView: View {
    @Binding var drawnText: String
    @Binding var drawnSuggestions: [String]
    @Binding var selectedDrawnText: String
    
    @Environment(\.undoManager) private var undoManager
    @State private var canvasView = PKCanvasView()
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    backStroke()
                }) {
                    Image(systemName: "arrow.uturn.left")
                        .font(.title2)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .padding(.leading, 16)
                .padding(.top, 16)
                
                Spacer()
                
                Button(action: {
                    redoStroke()
                }) {
                    Image(systemName: "arrow.uturn.right")
                        .font(.title2)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .padding(.trailing, 16)
                .padding(.top, 16)
                
                Spacer()
                
                Button(action: {
                    clearCanvas()
                }) {
                    Image(systemName: "trash")
                        .font(.title2)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .padding(.trailing, 16)
                .padding(.top, 16)
            }
            
            CanvasViewRepresentable(canvasView: $canvasView)
                .frame(height: 400)
                .border(Color.gray, width: 1)
                .padding()
            
            Button("Recognize Handwriting") {
                recognizeHandwriting()
            }
            .padding()
            
            if !drawnSuggestions.isEmpty {
                VStack {
                    Text("Choose from the suggestions:")
                        .padding(.top)
                    ForEach(drawnSuggestions, id: \.self) { suggestion in
                        Button(action: {
                            selectedDrawnText = suggestion
                        }) {
                            Text(suggestion)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(5)
                        }
                        .padding(5)
                    }
                }
            } else {
                Text("No suggestions available.")
            }
        }
    }

    private func clearCanvas() {
        canvasView.drawing = PKDrawing()
        drawnSuggestions.removeAll()
    }
    
    private func backStroke() {
        undoManager?.undo()
    }
    
    private func redoStroke() {
        undoManager?.redo()
    }
    
    private func recognizeHandwriting() {
        guard let image = canvasView.drawing.image(from: canvasView.bounds, scale: 2.0).cgImage else {
            print("Failed to generate CGImage from canvas drawing.")
            drawnText = "Failed to capture drawing."
            return
        }
        
        let request = VNRecognizeTextRequest { (request, error) in
            if let error = error {
                print("Error recognizing handwriting: \(error.localizedDescription)")
                drawnText = "Error recognizing handwriting: \(error.localizedDescription)"
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("No text recognized.")
                drawnSuggestions = []
                drawnText = "No recognizable text found."
                return
            }
            
            let recognizedStrings = observations.compactMap { observation -> String? in
                observation.topCandidates(1).first?.string
            }
            
            if recognizedStrings.isEmpty {
                drawnText = "No recognizable text found."
            } else {
                drawnText = recognizedStrings.joined(separator: " ")
                drawnSuggestions = recognizedStrings
            }
        }
        
        request.revision = VNRecognizeTextRequestRevision3
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["zh-Hans", "zh-Hant"]
        
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            print("Performing recognition...")
            try handler.perform([request])
        } catch {
            print("Failed to process handwriting: \(error.localizedDescription)")
            drawnText = "Failed to process handwriting: \(error.localizedDescription)"
        }
    }
}

struct CanvasViewRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.tool = PKInkingTool(.pen, color: .black, width: 20)
    }
}
