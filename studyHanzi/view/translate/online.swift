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
        guard !searchText.isEmpty else {
            completion(nil, [])
            return
        }
        
        let languageRecognizer = NLLanguageRecognizer()
        languageRecognizer.processString(searchText)
        
        if let detectedLanguage = languageRecognizer.dominantLanguage {
            let configuration: TranslationSession.Configuration
            switch detectedLanguage {
                case .vietnamese:
                    configuration = .init(source: .init(identifier: "vi"), target: .init(identifier: "zh-Hans"))
                default:
                    configuration = .init(target: .init(identifier: "vi"))
            }
            completion(configuration, [])
        } else {
            completion(nil, ["Unable to detect language."])
        }
    }
}





