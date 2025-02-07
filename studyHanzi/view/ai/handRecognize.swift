//
//  handRecognize.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 17/12/24.
//
import Foundation
import SwiftUI



class HanziDictionary {
    
    struct HanziCharacter:Equatable{
        let character:String
        let reading:String
    }
    static let dictionaryURL = Bundle.main.url(forResource: "phienam", withExtension: "txt")!
    fileprivate let dictionary: [String:String]
    
    init(url: URL) {
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            let lines = text.split(separator: "\n")
            let items = lines.compactMap({line->(String, String)? in
                let lineItem = line.split(separator: "=")
                guard let character = lineItem.first else {return nil}
                let value = lineItem.dropFirst().joined()
                return (String(character), value)
            })
            self.dictionary = Dictionary(items, uniquingKeysWith: {s1, _ in return s1})
        }
        catch let error {
            print(error)
            fatalError(error.localizedDescription)
        }
    }
    func hanziCharacter(for character: String) -> HanziCharacter? {
        if let data = self.dictionary[character] {
            return HanziCharacter(character: character, reading: data)
        } else {
            return nil
        }
    }
}
