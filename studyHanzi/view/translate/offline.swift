//
//  offline.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 23/11/24.
//

import Foundation



struct CSVHelper {
    static func loadCSV(fileName: String) -> [WordEntry] {
        guard let filePath = Bundle.main.path(forResource: fileName, ofType: "csv") else {
            return []
        }
        
        do {
            let content = try String(contentsOfFile: filePath, encoding: .utf8)
            var rows = content.components(separatedBy: "\n").filter { !$0.isEmpty }
            rows.removeFirst()
            return rows.compactMap { parseCsv($0) }
        } catch {
            print("Error loading CSV: \(error)")
            return []
        }
    }
    
    static func parseCsv(_ row: String) -> WordEntry? {
        var columns: [String] = []
        var value = ""
        var inQuotes = false
        
        for char in row {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                columns.append(value.trimmingCharacters(in: .whitespaces))
                value = ""
            } else {
                value.append(char)
            }
        }
        columns.append(value.trimmingCharacters(in: .whitespaces))
        guard columns.count == 8 else { return nil }
        
        return WordEntry(
            type: columns[0],
            word: columns[1],
            pinyin: columns[2],
            hanViet: columns[3],
            meaning: columns[4],
            example: columns[5],
            examplePinyin: columns[6],
            exampleMeaning: columns[7]
        )
    }
    

    static func searchWord(in entries: [WordEntry], for searchText: String) -> [String] {
        let lowercasedSearchText = searchText.lowercased()
        return entries.filter { entry in
            entry.word.lowercased().contains(lowercasedSearchText) ||
            entry.pinyin.lowercased().contains(lowercasedSearchText) ||
            entry.meaning.lowercased().contains(lowercasedSearchText) ||
            entry.hanViet.lowercased().contains(lowercasedSearchText)
        }
        .map { entry in
            """
            \(entry.type): \(entry.hanViet)
            \(entry.word)(\(entry.pinyin)): \(entry.meaning)
            example:
            \(entry.example)
            \(entry.examplePinyin)
            \(entry.exampleMeaning)
            """
        }
    }
    
    static func suggesWord(in entries: [WordEntry], for searchText: String) -> [String] {
        let lowercasedSearchText = searchText.lowercased()
        
        let startsWithSearchText = entries.compactMap { entry in
            if entry.word.lowercased().hasPrefix(lowercasedSearchText) {
                return entry.word
            } else if entry.pinyin.lowercased().hasPrefix(lowercasedSearchText) {
                return entry.pinyin
            } else if entry.meaning.lowercased().hasPrefix(lowercasedSearchText) {
                return entry.meaning
            } else if entry.hanViet.lowercased().hasPrefix(lowercasedSearchText) {
                return entry.hanViet
            }
            return nil
        }
        
        let containsSearchText = entries.compactMap { entry in
            if entry.word.lowercased().contains(lowercasedSearchText) {
                return entry.word
            } else if entry.pinyin.lowercased().contains(lowercasedSearchText) {
                return entry.pinyin
            } else if entry.meaning.lowercased().contains(lowercasedSearchText) {
                return entry.meaning
            } else if entry.hanViet.lowercased().contains(lowercasedSearchText) {
                return entry.hanViet
            }
            return nil
        }
        
        let allSuggestions = (startsWithSearchText + containsSearchText)
            .uniqued()
            .prefix(10)
        return Array(allSuggestions)
    }
}

extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
