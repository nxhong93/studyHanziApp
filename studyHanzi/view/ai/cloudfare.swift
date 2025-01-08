import Foundation
import NaturalLanguage



class cloudfareService {
    private let streamService = cloudfareStream()
    func runLlmQuery(
        inputText: String,
        onPartialResult: @escaping (String) -> Void,
        onComplete: @escaping (Result<String, Error>) -> Void
    ) {
        detectLanguage(for: inputText) { [weak self] detectedLanguage in
            guard let self = self else { return }
            
            let param = cloudfareLanguageConfig(inputText: inputText, detectdLanguage: detectedLanguage)
            self.sendLlmRequest(with: param, onPartialResult: onPartialResult, onComplete: onComplete)
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
    
    public func sendLlmRequest(
        with param: cloudfareLanguageConfig,
        onPartialResult: @escaping (String) -> Void,
        onComplete: @escaping (Result<String, Error>) -> Void
    ) {
        guard let randomAccount = cloudfareConfig.llmAcc.randomElement() else {
            onComplete(.failure(CustomError.noAccountsAvailable))
            return
        }
        let urlString = "https://api.cloudflare.com/client/v4/accounts/\(randomAccount.accountId)/ai/run/\(cloudfareConfig.modelName)"
        guard let url = URL(string: urlString) else {
            onComplete(.failure(CustomError.invalidURL))
            return
        }
        let headers = [
            "Authorization": "Bearer \(randomAccount.token)",
            "Content-Type": "application/json"
        ]
        let messages: [[String: String]] = [
            ["role": "system", "content": param.systemPrompt],
            ["role": "user", "content": param.userPrompt]
        ]
        let body: [String: Any] = ["messages": messages, "stream": true]
        streamService.sendStreamingRequest(
            url: url,
            headers: headers,
            body: body,
            onPartialResult: onPartialResult,
            onComplete: onComplete
        )
    }
}
