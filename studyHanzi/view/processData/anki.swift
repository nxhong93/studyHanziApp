//
//  anki.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 18/1/25.
//
import Foundation
import ZIPFoundation
import SQLite



class AnkiFileManager {
    static let shared = AnkiFileManager()
    private var username: String = ""
    
    private init() {}
    
    func setUsername(_ newUsername: String) {
        if let atSymbolIndex = newUsername.firstIndex(of: "@") {
            self.username = String(newUsername[..<atSymbolIndex])
        } else {
            self.username = newUsername
        }
    }

    func loadFlashcards(from filename: String, level: String, completion: @escaping ([Flashcard]) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                guard let fileURL = Bundle.main.url(forResource: filename, withExtension: "anki2") else {
                    print("Error: File \(filename).anki2 not found in the bundle.")
                    completion([])
                    return
                }

                let db = try Connection(fileURL.path)
                let notes = Table("notes")
                let fieldsColumn = SQLite.Expression<String>("flds")
                var flashcards: [Flashcard] = []
                let learnedDBURL = self.getLearnedDatabaseURL()
                
                if !FileManager.default.fileExists(atPath: learnedDBURL.path) {
                    print("Learned database not found, creating new one...")
                    try self.createLearnedDatabase(at: learnedDBURL)
                }
                let learnedDB = try Connection(learnedDBURL.path)
                let learnedTable = Table("learned_card")
                let fileColumn = SQLite.Expression<String>("filename")
                let idColumn = SQLite.Expression<String>("id")
                let learnedCount = (try? learnedDB.scalar(learnedTable.count)) ?? 0
                
                for note in try db.prepare(notes) {
                    if let fieldsString = try? note.get(fieldsColumn) {
                        let parts = fieldsString.components(separatedBy: "\u{1F}")
                        
                        if parts.count >= 2 {
                            let (frontText, backText) = self.frontBack(filename: filename, parts: parts)
                            var isLearned = false
                            if learnedCount > 0 {
                                isLearned = (try? learnedDB.scalar(
                                    learnedTable.filter(fileColumn == filename && idColumn == parts[0]).count
                                )) ?? 0 > 0
                            }
                            let flashcard = Flashcard(
                                id: parts[0],
                                front: frontText,
                                back: backText,
                                level: level,
                                isLearned: isLearned,
                                fileName: filename
                            )
                            flashcards.append(flashcard)
                        }
                    } else {
                        print("Column 'flds' is NULL for this row: \(note)")
                    }
                }

                completion(flashcards)
            } catch {
                print("Error while loading flashcards: \(error.localizedDescription)")
                completion([])
            }
        }
    }


    func updateLearnedStatus(for flashcard: Flashcard, to status: Bool) {
        let dbURL = getLearnedDatabaseURL()
        
        DispatchQueue.global(qos: .background).async {
            do {
                if !FileManager.default.fileExists(atPath: dbURL.path) {
                    try self.createLearnedDatabase(at: dbURL)
                    print("✅ Tạo cơ sở dữ liệu learned_card thành công.")
                }
                
                let db = try Connection(dbURL.path)
                let table = Table("learned_card")
                let fileColumn = SQLite.Expression<String>("filename")
                let idColumn = SQLite.Expression<String>("id")
                
                try db.run(table.create(ifNotExists: true) { t in
                    t.column(fileColumn)
                    t.column(idColumn)
                })
                
                let query = table.filter(fileColumn == flashcard.fileName && idColumn == flashcard.id)
                let existingCount = try db.scalar(query.count)
                
                if status {
                    if existingCount == 0 {
                        try db.run(table.insert(fileColumn <- flashcard.fileName, idColumn <- flashcard.id))
                        print("✅ Đã đánh dấu card \(flashcard.id) trong file \(flashcard.fileName) là đã học.")
                    } else {
                        print("⚠️ Card \(flashcard.id) đã được đánh dấu trước đó.")
                    }
                } else {
                    if existingCount > 0 {
                        try db.run(query.delete())
                        print("✅ Đã bỏ đánh dấu card \(flashcard.id) trong file \(flashcard.fileName).")
                    } else {
                        print("⚠️ Card \(flashcard.id) chưa được đánh dấu trước đó.")
                    }
                }
            } catch {
                print("❌ Lỗi khi cập nhật trạng thái học: \(error.localizedDescription)")
            }
        }
    }

    private func getLearnedDatabaseURL() -> URL {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dbFilename = "\(username)_learned_card.sqlite"
        return documentsURL.appendingPathComponent(dbFilename)
    }
    
    private func createLearnedDatabase(at url: URL) throws {
        let db = try Connection(url.path)
        let table = Table("learned_card")
        let fileColumn = SQLite.Expression<String>("filename")
        let idColumn = SQLite.Expression<String>("id")

        try db.run(table.create(ifNotExists: true) { t in
            t.column(fileColumn)
            t.column(idColumn)
        })

        print("✅ Database \(url.lastPathComponent) created successfully.")
    }


    private func frontBack(filename: String, parts: [String]) -> (String, String) {
        func cleanExtraNewlines(_ text: String) -> String {
            let cleanedText = text
                .components(separatedBy: "\n")
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .joined(separator: "\n")
            return cleanedText
        }

        var frontText: String
        var backText: String

        if filename.contains("englishVocab") {
            frontText = "\(parts[7])\n\(parts[2])\n\(parts[3])".hideContentBetweenDelimiters()
            backText = "\(parts[1])\n\(parts[6])\n\(parts[10])"
        } else {
            frontText = parts[0]
            backText = parts[1]
        }

        frontText = cleanExtraNewlines(frontText)
        backText = cleanExtraNewlines(backText)

        return (frontText, backText)
    }
}
