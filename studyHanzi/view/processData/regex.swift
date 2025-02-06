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
        let withoutNbsp = self.replacingOccurrences(of: "&nbsp", with: "")
        let withoutDelimiters = withoutNbsp.replacingOccurrences(of: #"\{\{.*?\}\}"#, with: "___", options: .regularExpression)
        let withoutDelimiters1 = withoutDelimiters.replacingOccurrences(of: #"::.*?\}\}"#, with: "___", options: .regularExpression)
        let withNewLines = withoutDelimiters1.replacingOccurrences(of: #"<br\s*/?>"#, with: "\n", options: .regularExpression)
        return withNewLines
    }
}


