//
//  learnView.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 18/11/24.
//

import SwiftUI



struct learnView: View {
    @Binding var isDarkMode: Bool
    @State private var selectedLanguage: String?
    @State private var selectedSubject: String?
    @State private var selectedLevel: String?

    var body: some View {
        NavigationStack {
            List {
                ForEach(learnLanguage.allCases, id: \.self) { language in
                    ForEach(language.subjects, id: \.self) { subject in
                        DisclosureGroup(
                            content: {
                                ForEach(language.levels, id: \.self) { level in
                                    NavigationLink(
                                        value: levelDetail(language: language.rawValue, subject: subject, level: level)
                                    ) {
                                        Text(level.capitalized)
                                            .foregroundColor(.primary)
                                            .padding(.leading)
                                    }
                                }
                            },
                            label: {
                                HStack {
                                    Text(language.flag)
                                    Spacer()
                                    Text(subject.capitalized)
                                }
                            }
                        )
                    }
                }
            }
            .navigationDestination(for: levelDetail.self) { detail in
                getDetailView(language: detail.language, subject: detail.subject, level: detail.level)
                    .navigationBarBackButtonHidden(true)
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }

    @ViewBuilder
    func getDetailView(language: String, subject: String, level: String) -> some View {
        if language == "english" && subject == "vocabulady" {
            englishVocabView(level: level, isDarkMode: $isDarkMode)
        } else if language == "english" && subject == "grammer" {
            englishGrammerView(level: level, isDarkMode: $isDarkMode)
        } else {
            learnView(isDarkMode: $isDarkMode)
        }
    }
}


#Preview {
    learnView(
        isDarkMode: .constant(true)
    )
}
