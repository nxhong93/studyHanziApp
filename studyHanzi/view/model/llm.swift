//
//  llm.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 24/11/24.
//

import SwiftUI
import Foundation


struct HuggingFaceApi{
    let apiUrl = llmConfig.apiUrl
    let token: String
    
    init(token: String) {
        self.token = token
    }
    
    func query(payload: [String: Any], completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: apiUrl) else {
            completion(.failure(NSError(domain: "Invalid url", code: 0, userInfo: nil)))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(llmConfig.authorization, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload)
            request.httpBody = jsonData
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No Data", code: 0, userInfo: nil)))
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any], let generatedText = jsonResponse["generated_text"] as? String {
                    completion(.success(generatedText))
                } else {
                    completion(.failure(NSError(domain: "Invalid Response", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
