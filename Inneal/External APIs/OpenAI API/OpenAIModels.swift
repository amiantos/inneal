//
//  OpenAIModels.swift
//  Inneal
//
//  Created by Brad Root on 4/10/24.
//

import Foundation

struct GPTParameters: Codable {
    let model: String
    let messages: [GPTMessage]
}

struct GPTMessage: Codable {
    let role: String
    let content: String
}
