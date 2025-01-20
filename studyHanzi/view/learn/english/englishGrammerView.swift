//
//  englishGrammerView.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 16/1/25.
//

import SwiftUI

struct englishGrammerView: View {
    @State var level: String
    @State var isDarkMode: Bool
    
    var body: some View {
        Text("Hello, grammer!")
    }
}

#Preview {
    englishGrammerView(
        level: "beginner",
        isDarkMode: true
    )
}
