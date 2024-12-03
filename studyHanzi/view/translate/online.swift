////
////  online.swift
////  studyHanzi
////
////  Created by nguyen xuan hong on 20/11/24.
////

import Foundation
import NaturalLanguage
import Translation



struct TranslationHelper {
    static func onlineTranslate(
        searchText: String,
        completion: @escaping (TranslationSession.Configuration?, [String]) -> Void
    ) {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            completion(nil, ["No text to translate."])
            return
        }

        let languageRecognizer = NLLanguageRecognizer()
        languageRecognizer.processString(trimmedText)
        
        if let detectedLanguage = languageRecognizer.dominantLanguage {
            var configuration: TranslationSession.Configuration?
            switch detectedLanguage {
            case .vietnamese:
                configuration = TranslationSession.Configuration(
                    source: .init(identifier: "vi"),
                    target: .init(identifier: "zh-Hans")
                )
            case .simplifiedChinese:
                configuration = .init(
                    source: .init(identifier: "zh-Hans"),
                    target: .init(identifier: "vi")
                )
            default:
                configuration = .init(
                    target: .init(identifier: "vi")
                )
            }
            completion(configuration, [])
        } else {
            completion(nil, ["Unable to detect language."])
        }
    }
}





