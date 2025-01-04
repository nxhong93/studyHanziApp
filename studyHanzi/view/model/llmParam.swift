//
//  llm.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 24/11/24.
//

import SwiftUI
import Foundation
import Combine


struct llmModel {
    let name: String
}

struct cloudfareAccount {
    let accoundId: String
    let token: String
}


//list_model = [
//    "@hf/nousresearch/hermes-2-pro-mistral-7b",
//    "@cf/meta/llama-3.1-70b-instruct",
//    "@cf/meta/llama-3.1-8b-instruct-fast",
//    "@hf/thebloke/neural-chat-7b-v3-1-awq",
//    "@hf/thebloke/openhermes-2.5-mistral-7b-awq",
//    "@cf/fblgit/una-cybertron-7b-v2-bf16",
//    "@hf/thebloke/zephyr-7b-beta-awq",
//]

struct cloudfareConfig {
    static let model_name: String = "@hf/nousresearch/hermes-2-pro-mistral-7b"
    static let llm_acc: [cloudfareAccount] = [
        cloudfareAccount(accoundId: "37ee5390db6343179564a8597dd5f8b8", token: "8j58LQhSA05iLnxj3LOWz1L0D4gWum0tbXa80nzA"),
        cloudfareAccount(accoundId: "c2aad90a2fc36cc3563418daf24dd2c6", token: "UKV7SeFZWUdz4C2nsjlUPqmJDwAZxXpE_GfKa45Y"),
        cloudfareAccount(accoundId: "c28b912ed79aef66692a02df93ef140a", token: "P03kbSkgEJhlZAnKQ7OijsK7JlALwwVzwjxjIFyz")
    ]
}

struct cloudfareLanguageConfig {
    let systemPrompt: String
    let userPrompt: String
    
    init(inputText: String, detectdLanguage: String) {
        if detectdLanguage == "vi" {
            self.systemPrompt = "You are a language expert. Translate the user's sentence into Chinese."
            self.userPrompt = "Translate the following Vietnamese sentence into Chinese: \(inputText)"
        } else {
            self.systemPrompt = "You are a language expert. Translate the user's sentence into Vietnamese."
            self.userPrompt = "Translate the following sentence into Vietnamese: \(inputText)"
        }
    }
}

enum CustomError: Error {
    case noAccountsAvailable
    case invalidURL
    case noData
    case invalidResponseFormat
    case apiError(String)
}

struct apiAccount {
    let api: String
}

struct llmConfig {
    let modelName: String
    let llmAccounts: apiAccount?
    let modelUrl: String
    let systemPrompt: String
    let userPrompt: String
    let inputImage: String
}

struct cloudgroqSettings {
    static let modelName: String = "llama-3.2-90b-vision-preview"
    static let llmAccounts: [apiAccount] = [
        apiAccount(api: "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"),
        apiAccount(api: "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"),
        apiAccount(api: "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")
    ]
    static let llmUrl: String = "https://api.groq.com/openai/v1/chat/completions"
}

struct openRouterSettings {
    static let modelName: String = "google/gemini-2.0-flash-exp:free"
    static let llmAccounts: [apiAccount] = [
        apiAccount(api: "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"),
        apiAccount(api: "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"),
        apiAccount(api: "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")
    ]
    static let llmUrl: String = "https://openrouter.ai/api/v1/chat/completions"
}
