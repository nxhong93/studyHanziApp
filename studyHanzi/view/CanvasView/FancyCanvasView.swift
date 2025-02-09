//
//  FancyCanvasView.swift
//  KanjiLookup-SwiftUI
//
//  Created by Morten Bertz on 2020/07/02.
//  Copyright © 2020 telethon k.k. All rights reserved.
//

#if canImport(UIKit)

import Foundation
import PencilKit
import SwiftUI


struct FancyCanvasWrapper: UIViewRepresentable {
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var canvas: FancyCanvasWrapper
        init(_ canvas: FancyCanvasWrapper) {
            self.canvas = canvas
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            let strokes=canvasView.drawing.strokes
                .map({$0.path.interpolatedPoints(by: .parametricStep(1))
                        .map({$0.location})})
            self.canvas.drawnStrokes.strokes=strokes
        }
        func canvasView(_ canvasView: PKCanvasView, didFinishDrawing stroke: PKStroke) {
            self.canvas.recognizer.finishStroke()
        }
    }
    
    @Binding var canvas : PKCanvasView
    @Binding var strokeColor : UIColor
    @Binding var strokeWidth : CGFloat
    
    class DrawnStrokes:ObservableObject{
        @Published var strokes=[[CGPoint]]()
    }
    

    let drawnStrokes=DrawnStrokes()
    let recognizer = Recognizer()
    
    func makeCoordinator() -> Coordinator {
        let coordinator=Coordinator(self)
        return coordinator
    }

    func makeUIView(context: Context) -> PKCanvasView {
        
        canvas.drawingPolicy = .anyInput
        canvas.delegate = context.coordinator
        canvas.isScrollEnabled=false
        canvas.backgroundColor = .clear
        canvas.isOpaque=false
        return canvas
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        canvas.tool = PKInkingTool(.pen, color: strokeColor, width: strokeWidth)
    }
}



public struct FancyCanvas:View, CanvasView{
    
    @EnvironmentObject var recognizer: Recognizer
    @EnvironmentObject var configuration: CanvasConfiguration
    @State private var canvasView = PKCanvasView()
    
    public var body: some View{
        let fancyCanvas=FancyCanvasWrapper(
            canvas: $canvasView,
            strokeColor: $configuration.strokeColor,
            strokeWidth: $configuration.strokeWidth
        )
        
        let buttons=HStack(alignment: .center, spacing: 0, content: {
            Button(action: {
                canvasView.clear()
            }, label: {
                Image(systemName: "clear").imageScale(.large)
                    .foregroundColor(configuration.foregroundColor)
            })
            Spacer()
            Button(action: {
                canvasView.removeLastStroke()
                
            }, label: {
                Image(systemName: "arrow.counterclockwise").imageScale(.large)
                    .foregroundColor(configuration.foregroundColor)
                    
            })
        })
        
        
        return GeometryReader {geometry in
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(configuration.foregroundColor, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                        .foregroundColor(configuration.backgroundColor), alignment: .center)
                fancyCanvas
                if configuration.showStandardButtons{
                    buttons.padding()
                }
            }
            .onAppear {
                recognizer.canvasSize=geometry.size
                fancyCanvas.drawnStrokes.$strokes.subscribe(self.recognizer)
            }
        }
    }
    
    func clear(){
        canvasView.clear()
    }
    func undo() {
        canvasView.removeLastStroke()
    }
}


extension PKCanvasView{
    func removeLastStroke(){
        self.drawing.strokes=self.drawing.strokes.dropLast()
    }
    func clear(){
        self.drawing=PKDrawing()
        print("clear active!")
    }
}

#endif
