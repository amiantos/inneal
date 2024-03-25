//
//  TavernModels.swift
//  Inneal
//
//  Created by Brad Root on 4/10/24.
//

import Foundation

struct PygmalionChatCharacterResponse: Codable {
    let character: TavernPNGData
}

struct TavernSimple: Codable {
    let name: String
    let description: String
    let personality: String
    let firstMes: String
    let avatar: String
    let mesExample: String
    let scenario: String

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case personality
        case firstMes = "first_mes"
        case avatar
        case mesExample = "mes_example"
        case scenario
    }
}


struct TavernPNGData: Codable {
    let data: TavernCharacterData
    let spec: String
    let specVersion: String

    enum CodingKeys: String, CodingKey {
        case data
        case spec
        case specVersion = "spec_version"
    }
}

struct TavernCharacterData: Codable {
    let name: String
    let description: String
    let personality: String
    let firstMes: String
    let avatar: String
    let mesExample: String
    let scenario: String
    let creatorNotes: String
    let systemPrompt: String
    let postHistoryInstructions: String
    let alternateGreetings: [String]
    let tags: [String]
    let creator: String
    let characterVersion: String

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case personality
        case firstMes = "first_mes"
        case avatar
        case mesExample = "mes_example"
        case scenario
        case creatorNotes = "creator_notes"
        case systemPrompt = "system_prompt"
        case postHistoryInstructions = "post_history_instructions"
        case alternateGreetings = "alternate_greetings"
        case tags
        case creator
        case characterVersion = "character_version"
    }
}
