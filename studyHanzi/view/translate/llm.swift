import Foundation



class llmService {
    
    func runLlmQuery(
        inputText: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
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
            [
                "role": "system",
                "content": "You are a language expert. Translate the user's sentence as instructed."
            ],
            [
                "role": "user",
                "content": """
                Translate the following sentence into Chinese if it is in Vietnamese. \
                If the sentence is not in Vietnamese, translate it into Vietnamese. \
                No further words or explanations needed: \(inputText)
                """
            ]
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
