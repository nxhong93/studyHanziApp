//
//  streamText.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 8/1/25.
//

import Foundation



class cloudfareStream: NSObject, URLSessionDataDelegate {
    private var partialData = Data()
    private var onPartialResult: ((String) -> Void)?
    private var onComplete: ((Result<String, Error>) -> Void)?
    
    func sendStreamingRequest(
        url: URL,
        headers: [String: String],
        body: [String: Any],
        onPartialResult: @escaping (String) -> Void,
        onComplete: @escaping (Result<String, Error>) -> Void
    ) {
        self.onPartialResult = onPartialResult
        self.onComplete = onComplete

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let task = session.dataTask(with: request)
        task.resume()
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        partialData.append(data)
        
        if let responseString = String(data: partialData, encoding: .utf8) {
            let lines = responseString.split(separator: "\n")
            for line in lines {
                if line.starts(with: "data: ") {
                    let jsonData = line.replacingOccurrences(of: "data: ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    if let json = try? JSONSerialization.jsonObject(with: Data(jsonData.utf8), options: []) as? [String: Any],
                       let content = json["response"] as? String {
                        DispatchQueue.main.async {
                            self.onPartialResult?(content)
                        }
                    }
                }
            }
            partialData.removeAll()
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.onComplete?(.failure(error))
            }
        } else {
            DispatchQueue.main.async {
                self.onComplete?(.success("Stream completed"))
            }
        }
    }
}
