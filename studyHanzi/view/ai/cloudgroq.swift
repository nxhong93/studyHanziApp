//
//  cloudgroq.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 1/1/25.
//

import Foundation



class CloudgroqService: ObservableObject {
    func translateImageWithLLMVision(
        imageBase: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let config = llmConfig(
            modelName: cloudgroqSettings.modelName,
            llmAccounts: cloudgroqSettings.llmAccounts.randomElement(),
            modelUrl: cloudgroqSettings.llmUrl,
            systemPrompt: "Dịch ảnh sang tiếng Việt",
            userPrompt: "Dịch ngắn gọn không giải thích trong ảnh này có chữ tiếng trung nào hãy chuyển sang tiếng Việt với format là 'tiếng trung: dịch tiếng việt'",
            inputImage: imageBase
        )
        self.sendLlmRequest(with: config, completion: completion)
    }
    
    public func sendLlmRequest(with param: llmConfig, completion: @escaping (Result<String, Error>) -> Void) {
        guard let randomAccount = param.llmAccounts else {
            completion(.failure(CustomError.noAccountsAvailable))
            return
        }
        
        let urlString = param.modelUrl
        guard let url = URL(string: urlString) else {
            completion(.failure(CustomError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(randomAccount.api)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": param.userPrompt],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(param.inputImage)"
                            ]
                        ]
                    ]
                ]
            ],
            "model": param.modelName,
            "temperature": 1,
            "max_tokens": 1024,
            "top_p": 1
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(CustomError.noData))
                return
            }
            
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let choices = jsonResponse?["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(.success(content))
                } else {
                    completion(.failure(CustomError.invalidResponseFormat))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
