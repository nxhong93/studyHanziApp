//
//  ttsParam.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 6/2/25.
//

import Foundation



enum ttsVoice: String {
    case english = "en-US"
    case chinese = "cmn-CN"
    case japanese = "ja-JP"
    
    var name: [String] {
        switch self {
        case .english: return [
            "en-US-Wavenet-A",
            "en-US-Wavenet-B",
            "en-US-Wavenet-C",
            "en-US-Wavenet-D",
            "en-US-Wavenet-E",
            "en-US-Wavenet-F",
            "en-US-Wavenet-G",
            "en-US-Wavenet-H",
            "en-US-Wavenet-I",
            "en-US-Wavenet-J"
        ]
        case .chinese: return [
            "cmn-CN-Wavenet-A",
            "cmn-CN-Wavenet-B",
            "cmn-CN-Wavenet-C",
            "cmn-CN-Wavenet-D"
        ]
        case .japanese: return [
            "ja-JP-Wavenet-A",
            "ja-JP-Wavenet-B",
            "ja-JP-Wavenet-C",
            "ja-JP-Wavenet-D"
        ]
        }
    }
}
