//
//  TextRecognizer.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 10/12/24.
//

import Foundation
import Vision
import SwiftUI



struct TextRecognizer {
    static func recognizeTextWithRects(in image: UIImage, completion: @escaping ([(text: String, rect: CGRect)]) -> Void) {
        guard let cgImage = image.cgImage else { return }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { (request, error) in
            guard let results = request.results as? [VNRecognizedTextObservation] else {
                completion([])
                return
            }

            let textRects = results.compactMap { observation -> (String, CGRect)? in
                if let topCandidate = observation.topCandidates(1).first {
                    return (topCandidate.string, observation.boundingBox)
                }
                return nil
            }
            completion(textRects)
        }
        request.revision = VNRecognizeTextRequestRevision3
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["zh-Hans", "zh-Hant"]

        DispatchQueue.global(qos: .userInitiated).async {
            try? requestHandler.perform([request])
        }
    }
}
