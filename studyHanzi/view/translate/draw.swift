//
//  draw.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 5/12/24.
//
import SwiftUI
import PencilKit
import Foundation



struct HanziInfoView: View {
    var character: HanziDictionary.HanziCharacter

    var body: some View {
        HStack {
            Text(character.character)
            Spacer()
            Text(character.reading)
                .foregroundColor(.gray)
                .multilineTextAlignment(.trailing)
        }
        .contextMenu {
            Button(action: {
                UIPasteboard.general.string = self.character.character
            }, label: {
                Text("Character")
            })
            Button(action: {
                UIPasteboard.general.string = self.character.reading
            }, label: {
                Text("Reading")
            })
        }
    }
}


struct DrawingView: View {
    
    let recognize = Recognizer()
    let dictionary = HanziDictionary(url: HanziDictionary.dictionaryURL)
    @State var characters = [HanziDictionary.HanziCharacter]()
    @Binding var selectedCharacter: String
    @Environment(\.dismiss) var drawDismiss
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            List(characters, id: \.character) {entry in
                HanziInfoView(character: entry)
                    .onTapGesture {
                        selectedCharacter = entry.character
                        recognize.clear()
                        drawDismiss()
                    }
            }
            FancyCanvas()
                .environmentObject(recognize)
                .environmentObject(CanvasConfiguration())
                .padding(8)
                .aspectRatio(1, contentMode: .fit)
        }
        .onReceive(recognize.$characters) { newCharacter in
            self.characters = newCharacter.compactMap { dictionary.hanziCharacter(for: $0)}
        }
    }
}
