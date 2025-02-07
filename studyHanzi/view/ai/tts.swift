//
//  tts.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 4/2/25.
//
import Foundation
import AVFoundation



class GoogleTTS {
    private var apiKey: String?
    private var audioPlayer: AVAudioPlayer?
    
    init() {
        loadAPIKey()
    }
    
    private func loadAPIKey() {
        guard let url = Bundle.main.url(forResource: "tts", withExtension: "json") else {
            print("Error: tts.json file not found")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: String]
            apiKey = json?["private_key_id"]
            
            if apiKey == nil {
                print("Warning: API key not found in tts.json")
            }
        } catch {
            print("Error loading API key: \(error.localizedDescription)")
        }
    }
    
    func synthesizeSpeech(
        text: String,
        languageCode: String,
        voiceName: String,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        guard let apiKey = apiKey else {
            completion(.failure(TTSError.missingAPIKey))
            return
        }
        
        let endpoint = "https://texttospeech.googleapis.com/v1beta1/text:synthesize"
        guard let url = URL(string: "\(endpoint)?key=\(apiKey)") else {
            completion(.failure(TTSError.invalidURL))
            return
        }
        
        let requestBody: [String: Any] = [
            "input": ["text": text],
            "voice": [
                "languageCode": languageCode,
                "name": voiceName
            ],
            "audioConfig": [
                "audioEncoding": "LINEAR16",
                "effectsProfileId": [
                    "small-bluetooth-speaker-class-device"
                ],
                "pitch": 0,
                "speakingRate": 1
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(.failure(TTSError.jsonEncodingFailed))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(TTSError.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let statusError = TTSError.serverError(statusCode: httpResponse.statusCode)
                completion(.failure(statusError))
                return
            }
            
            guard let data = data else {
                completion(.failure(TTSError.noDataReceived))
                return
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let audioContent = json["audioContent"] as? String,
                      let audioData = Data(base64Encoded: audioContent) else {
                    throw TTSError.invalidResponseFormat
                }
                completion(.success(audioData))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func playAudio(data: Data) {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Audio playback error: \(error.localizedDescription)")
        }
    }
    
    enum TTSError: Error, LocalizedError {
        case missingAPIKey
        case invalidURL
        case jsonEncodingFailed
        case invalidResponse
        case serverError(statusCode: Int)
        case noDataReceived
        case invalidResponseFormat
        
        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "API key is missing or invalid"
            case .invalidURL:
                return "Invalid API endpoint URL"
            case .jsonEncodingFailed:
                return "Failed to encode request body"
            case .invalidResponse:
                return "Received invalid server response"
            case .serverError(let code):
                return "Server error (status code: \(code))"
            case .noDataReceived:
                return "No data received from server"
            case .invalidResponseFormat:
                return "Invalid response format from server"
            }
        }
    }
}
