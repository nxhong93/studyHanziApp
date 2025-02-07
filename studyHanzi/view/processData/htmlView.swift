//
//  htmlView.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 19/1/25.
//

import SwiftUI
import WebKit



public func decodeHTML(_ html: String) -> String {
    guard let data = html.data(using: .utf8) else { return html }
    let decoded = try? NSAttributedString(data: data,
                                          options: [.documentType: NSAttributedString.DocumentType.html,
                                                    .characterEncoding: String.Encoding.utf8.rawValue],
                                          documentAttributes: nil)
    return decoded?.string ?? html
}
