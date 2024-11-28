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


struct llmConfig {
    static let apiUrl: String = "https://api-inference.huggingface.co/models/Qwen/Qwen2.5-1.5B"
    static let apiToken: String = "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"
    static let authorization: String = "Bearer \(apiToken)"
    static let temperature: Double = 0.8
    static let maxNewTokens: Int = 50
    static let seed: Int = 32
    static let promt: String = "bạn là trợ lý ngôn ngũ, nhiệm vụ của bạn là dịch câu sang tiếng trung nếu câu đầu vào là tiếng việt, nếu câu đầu vào không phải tiếng việt thì dịch sang tiếng trung."
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
