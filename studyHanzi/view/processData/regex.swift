//
//  regex.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 14/12/24.
//

import Foundation



func isChinese(_ text: String) -> Bool {
    let chinesePattern = "^[\\p{Han}\\p{Punct}\\p{Nd}]+$"
    let chineseRegex = try! NSRegularExpression(pattern: chinesePattern)
    let chineseRange = NSRange(location: 0, length: text.utf16.count)
    
    if chineseRegex.firstMatch(in: text, options: [], range: chineseRange) == nil {
        return false
    }
    
    let hanPattern = "\\p{Han}"
    let hanRegex = try! NSRegularExpression(pattern: hanPattern)
    let hanRange = NSRange(location: 0, length: text.utf16.count)
    
    return hanRegex.firstMatch(in: text, options: [], range: hanRange) != nil
}


extension String {
    func hideContentBetweenDelimiters() -> String {
        let withoutDelimiters = self.replacingOccurrences(of: #"\{\{.*?\}\}"#, with: "___", options: .regularExpression)
        let withNewLines = withoutDelimiters.replacingOccurrences(of: #"<br\s*/?>"#, with: "\n", options: .regularExpression)
        return withNewLines
    }
}


