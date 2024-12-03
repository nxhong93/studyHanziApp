//
//  searchParam.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 18/11/24.
//

import Foundation


enum SearchType: String, CaseIterable {
    case online = "Online"
    case offline = "Offline"
    case llm = "LLM"
    case image = "Image"
    
    var icon: String {
        switch self {
        case .online: return "globe"
        case .offline: return "tray.fill"
        case .llm: return "brain.head.profile"
        case .image: return "photo"
        }
    }
}



struct csvConfig {
    static let csvFileName: String = "hsk"
    
}


struct WordEntry {
    let type: String
    let word: String
    let pinyin: String
    let hanViet: String
    let meaning: String
    let example: String
    let examplePinyin: String
    let exampleMeaning: String
}


enum Language: String, CaseIterable {
    case vietnamese = "vi-VN"
    case english = "en-US"
    case chinese = "zh-CN"
    
    var flag: String {
        switch self {
        case .vietnamese: return "🇻🇳"
        case .english: return "🇬🇧"
        case .chinese: return "🇨🇳"
        }
    }
    
    var localeIdentifier: String {
        return self.rawValue
    }
}


