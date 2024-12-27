import Foundation
import NaturalLanguage




class llmService {
    func runLlmQuery(
        inputText: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        detectLanguage(for: inputText) { [weak self] detectedLanguage in
            guard let self = self else { return }
            
            let param = llmLanguageConfig(inputText: inputText, detectdLanguage: detectedLanguage)
            self.sendLlmRequest(with: param, completion: completion)
        }
    }
    
    public func detectLanguage(for text: String, completion: @escaping (String) -> Void) {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        guard let detectedLanguage = recognizer.dominantLanguage?.rawValue else {
            completion("unknown")
            return
        }
        
        completion(detectedLanguage)
    }
    
    public func sendLlmRequest(with param: llmLanguageConfig, completion: @escaping (Result<String, Error>) -> Void) {
        guard let randomAccount = llmConfig.llm_acc.randomElement() else {
            completion(.failure(CustomError.noAccountsAvailable))
            return
        }
        
        let urlString = "https://api.cloudflare.com/client/v4/accounts/\(randomAccount.accoundId)/ai/run/\(llmConfig.model_name)"
        guard let url = URL(string: urlString) else {
            completion(.failure(CustomError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(randomAccount.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let messages: [[String: String]] = [
            ["role": "system", "content": param.systemPrompt],
            ["role": "user", "content": param.userPrompt]
        ]
        
        let body: [String: Any] = ["messages": messages]
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
                if let r = jsonResponse?["result"] as? [String: Any],
                   let rp = r["response"] as? String {
                    completion(.success(rp))
                } else {
                    completion(.failure(CustomError.invalidResponseFormat))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

