//
//  learnParam.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 16/1/25.
//

import Foundation



struct levelDetail: Hashable {
    let language: String
    let subject: String
    let level: String
}

enum learnLanguage: String, CaseIterable {
    case english = "english"
    case chinese = "chinese"
    case japanese = "japanese"
    
    var flag: String {
        switch self {
            case .english: return "🇬🇧"
            case .chinese: return "🇨🇳"
            case .japanese: return "🇯🇵"
        }
    }
    var subjects: [String] {
        switch self {
            case .english: return ["vocabulady", "grammer", "common phrases"]
            case .chinese: return ["hanzi", "vocabulady", "grammer", "common phrases"]
            case .japanese: return ["kanji", "vocabulady", "grammer", "common phrases"]
        }
    }
    var levels: [String] {
        switch self {
            case .english: return ["book1", "book2", "book3", "book4", "book5", "book6", "all level"]
            case .chinese: return ["hsk1", "hsk2", "hsk3", "hsk4", "hsk5", "hsk6", "all level"]
            case .japanese: return ["n5", "n4", "n3", "n2", "n1", "all level"]
        }
    }
}

struct Flashcard {
    let id: String
    var front: String
    var back: String
    var level: String
    var isLearned: Bool
    var fileName: String
}
