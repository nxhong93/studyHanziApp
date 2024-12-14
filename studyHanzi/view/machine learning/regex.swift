//
//  regex.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 14/12/24.
//

import Foundation



func isChinese(_ text: String) -> Bool {
    // Kiểm tra nếu chuỗi này chỉ chứa chữ Hán và dấu câu
    let chinesePattern = "^[\\p{Han}\\p{Punct}]+$"
    let chineseRegex = try! NSRegularExpression(pattern: chinesePattern)
    let chineseRange = NSRange(location: 0, length: text.utf16.count)
    
    // Nếu chuỗi chứa ký tự không phải Hán hoặc dấu câu, trả về false
    if chineseRegex.firstMatch(in: text, options: [], range: chineseRange) == nil {
        return false
    }
    
    let hanPattern = "\\p{Han}"
    let hanRegex = try! NSRegularExpression(pattern: hanPattern)
    let hanRange = NSRange(location: 0, length: text.utf16.count)
    
    return hanRegex.firstMatch(in: text, options: [], range: hanRange) != nil
}



