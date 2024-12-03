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

struct llmAccount {
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

struct llmConfig {
    static let model_name: String = "@hf/nousresearch/hermes-2-pro-mistral-7b"
    static let llm_acc: [llmAccount] = [
        llmAccount(accoundId: "37ee5390db6343179564a8597dd5f8b8", token: "8j58LQhSA05iLnxj3LOWz1L0D4gWum0tbXa80nzA"),
        llmAccount(accoundId: "c2aad90a2fc36cc3563418daf24dd2c6", token: "UKV7SeFZWUdz4C2nsjlUPqmJDwAZxXpE_GfKa45Y"),
        llmAccount(accoundId: "c28b912ed79aef66692a02df93ef140a", token: "P03kbSkgEJhlZAnKQ7OijsK7JlALwwVzwjxjIFyz")
    ]
}

enum CustomError: Error {
    case noAccountsAvailable
    case invalidURL
    case noData
    case invalidResponseFormat
    case apiError(String)
}

