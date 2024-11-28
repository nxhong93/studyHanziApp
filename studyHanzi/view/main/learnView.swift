//
//  learnView.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 18/11/24.
//

import SwiftUI

struct learnView: View {
    @Binding var isDarkMode: Bool
    
    var body: some View {
        VStack {
            Text("Learn View")
                .font(.largeTitle)
                .foregroundColor(isDarkMode ? .white : .black)
                .padding()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isDarkMode ? Color.black : Color.white)
        .edgesIgnoringSafeArea(.all)
    }
}



#Preview {
    learnView(isDarkMode: .constant(true))
}
