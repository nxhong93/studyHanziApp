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
    private init() {}

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
                let learnedDB = try Connection(learnedDBURL.path)
                let learnedTable = Table("learned_card")
                let fileColumn = SQLite.Expression<String>("filename")
                let idColumn = SQLite.Expression<String>("id")

                for note in try db.prepare(notes) {
                    if let fieldsString = try? note.get(fieldsColumn) {
                        let parts = fieldsString.components(separatedBy: "\u{1F}")
                        if parts.count >= 2 {
                            let (frontText, backText) = self.frontBack(filename: filename, parts: parts)
                            let isLearned = try learnedDB.scalar(
                                learnedTable.filter(fileColumn == filename && idColumn == parts[0]).count
                            ) > 0
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
                let db = try Connection(dbURL.path)
                let table = Table("learned_card")
                let fileColumn = SQLite.Expression<String>("filename")
                let idColumn = SQLite.Expression<String>("id")
                
                if status {
                    let query = table.filter(fileColumn == flashcard.fileName && idColumn == flashcard.id)
                    if try db.scalar(query.count) == 0 {
                        try db.run(table.insert(fileColumn <- flashcard.fileName, idColumn <- flashcard.id))
                        print("Marked card \(flashcard.id) in file \(flashcard.fileName) as learned.")
                    } else {
                        print("Card \(flashcard.id) is already marked as learned.")
                    }
                } else {
                    let query = table.filter(fileColumn == flashcard.fileName && idColumn == flashcard.id)
                    if try db.scalar(query.count) > 0 {
                        try db.run(query.delete())
                        print("Unmarked card \(flashcard.id) in file \(flashcard.fileName) as learned.")
                    }else {
                        print("Card \(flashcard.id) was not marked as learned.")
                    }
                }
            } catch {
                print("Error while updating learned status: \(error.localizedDescription)")
            }
        }
    }

    private func getLearnedDatabaseURL() -> URL {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dbURL = documentsURL.appendingPathComponent("learned_card.sqlite")
        return dbURL
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
            backText = "\(parts[1])\n\(parts[10])\n\(parts[6])"
        } else {
            frontText = parts[0]
            backText = parts[1]
        }

        frontText = cleanExtraNewlines(frontText)
        backText = cleanExtraNewlines(backText)

        return (frontText, backText)
    }
}
