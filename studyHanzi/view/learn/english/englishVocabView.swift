//
//  englishVocabView.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 16/1/25.
//

import SwiftUI



struct englishVocabView: View {
    @State var level: String
    @State var isDarkMode: Bool
    
    var body: some View {
        Text("Hello, vocab!")
    }
}

#Preview {
    englishVocabView(
        level: "beginner",
        isDarkMode: true
    )
}
