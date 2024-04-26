//
//  Models.swift
//  Inneal
//
//  Created by Brad Root on 3/24/24.
//

import Foundation
import SwiftData
import SwiftUI


enum PreferredModel: String, Codable, CaseIterable, Identifiable {
    case any = "Any"
    case fim = "Fimbulvetr"
    case estopia = "Estopia"
    case fighter = "Tiefighter"
    case llama2 = "Any LLaMA2"
    case mistral = "Mistral/Mixtral"
    case pygma = "Pygmalion"
    var id: Self { self }
}

enum PreferredContextWindow: String, Codable, CaseIterable, Identifiable {
    case any = "Any"
    case medium = "4096+"
    case large = "8192+"
    var id: Self { self }
}

enum PreferredResponseSize: String, Codable, CaseIterable, Identifiable {
    case small = "Small"
    case large = "Large"
    var id: Self { self }
}

enum Services: String, Codable, CaseIterable, Identifiable {
    case horde = "AI Horde"
    case openAI = "OpenAI"
    case koboldai = "KoboldAI"
    case cohere = "Cohere"
    case anthropic = "Anthropic"
    case google = "Google"
    case openRouter = "OpenRouter"
    var id: Self { self }
}


@Model
class APIConfiguration {
    let serviceName: String = "horde"
    @Attribute(.allowsCloudEncryption) var configurationData: Data?

    init(serviceName: String, configurationData: Data) {
        if !["horde"].contains(serviceName) {
            fatalError("Service name \(serviceName) not recognized and cannot be saved.")
        }
        self.serviceName = serviceName
        self.configurationData = configurationData
    }
}

@Model
class Chat {
    var uuid: UUID = UUID()
    var dateCreated: Date = Date.now
    var dateUpdated: Date = Date.now
    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.chat) var messages: [ChatMessage]? = [ChatMessage]()
    @Relationship var characters: [Character]? = [Character]()

    var name: String = "Unnamed Chat"
    var userName: String?
    var allowMultilineReplies: Bool = false
    
    var service: Services = Services.horde

    // Horde Specific

    var hordeSettings: Data?
    var autoModeEnabled: Bool = true
    var preferredModel: PreferredModel = PreferredModel.any
    var preferredContextWindow: PreferredContextWindow = PreferredContextWindow.any
    var preferredResponseSize: PreferredResponseSize = PreferredResponseSize.small

    // Computed Properties

    var unwrappedMessages: [ChatMessage] {
        let unwrappedMessages: [ChatMessage] = messages ?? []
        return unwrappedMessages.sorted { $0.dateCreated < $1.dateCreated }
    }

    // Init

    init(name: String?, characters: [Character]) {
        self.name = name ?? "\(characters.first!.name)"
        self.characters = characters
    }

}

@Model
class ContentAlternate {
    let uuid: UUID = UUID()
    var string: String = ""
    @Relationship var message: ChatMessage?
    var dateCreated: Date = Date.now
    var request: String?
    var response: String?

    init(string: String, message: ChatMessage, request: String? = nil, response: String? = nil) {
        self.string = string
        self.message = message
        self.request = request
        self.response = response
    }
}

@Model
class ChatMessage {
    var uuid: UUID = UUID()
    var content: String = ""
    var fromUser: Bool = false
    var chat: Chat?
    var dateCreated: Date = Date.now
    var chatUUID: UUID = UUID()

    var request: String?
    var response: String?

    @Relationship var character: Character?
    @Relationship(deleteRule: .cascade, inverse: \ContentAlternate.message) var contentAlternates: [ContentAlternate]? = [ContentAlternate]()

    init(content: String, fromUser: Bool, chat: Chat? = nil, character: Character? = nil, request: String? = nil, response: String? = nil) {
        self.content = content
        self.fromUser = fromUser
        self.chat = chat
        chatUUID = chat?.uuid ?? UUID()
        self.character = character
        self.request = request
        self.response = response
    }

    var unwrappedContentAlternates: [ContentAlternate] {
        let unwrappedMessages: [ContentAlternate] = contentAlternates ?? []
        return unwrappedMessages.sorted { $0.dateCreated < $1.dateCreated }
    }
}

@Model
class Character: Transferable {
    var name: String = ""
    var characterDescription: String = ""
    var personality: String = ""
    var firstMessage: String = ""
    var exampleMessage: String = ""
    var scenario: String = ""
    var creatorNotes: String = ""
    var systemPrompt: String = ""
    var postHistoryInstructions: String = ""
    var alternateGreetings: [String] = [String]()
    var tags: [String] = [String]()
    var creator: String = ""
    var characterVersion: String = "main"
    var chubId: String = ""
    @Attribute(.externalStorage) var avatar: Data?
    @Relationship(deleteRule: .cascade, inverse: \Chat.characters) var chats: [Chat]? = [Chat]()
    @Relationship(inverse: \ChatMessage.character) var messages: [ChatMessage]? = [ChatMessage]()

    init(name: String, characterDescription: String, personality: String, firstMessage: String, exampleMessage: String, scenario: String, creatorNotes: String, systemPrompt: String, postHistoryInstructions: String, alternateGreetings: [String], tags: [String], creator: String, characterVersion: String, chubId: String, avatar: Data? = nil) {
        self.name = name
        self.characterDescription = characterDescription
        self.personality = personality
        self.firstMessage = firstMessage
        self.exampleMessage = exampleMessage
        self.scenario = scenario
        self.creatorNotes = creatorNotes
        self.systemPrompt = systemPrompt
        self.postHistoryInstructions = postHistoryInstructions
        self.alternateGreetings = alternateGreetings
        self.tags = tags
        self.creator = creator
        self.characterVersion = characterVersion
        self.chubId = chubId
        self.avatar = avatar
    }

    static var transferRepresentation: some TransferRepresentation {
        let rep = DataRepresentation<Character>(exportedContentType: .json) { character in
            let tavernData = TavernPNGData(data: TavernCharacterData(name: character.name, description: character.characterDescription, personality: character.personality, firstMes: character.firstMessage, avatar: "", mesExample: character.exampleMessage, scenario: character.scenario, creatorNotes: character.creatorNotes, systemPrompt: character.systemPrompt, postHistoryInstructions: character.postHistoryInstructions, alternateGreetings: character.alternateGreetings, tags: character.tags, creator: character.creator, characterVersion: character.characterVersion), spec: "chara_card_v2", specVersion: "2.0")
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            return try! encoder.encode(tavernData)
        }
        return rep.suggestedFileName { obj in obj.suggestedFileName }
    }
    var suggestedFileName: String { "\(name).json" }
}

class CharacterPNGExporter: Transferable {
    let character: Character

    init(character: Character) {
        self.character = character
    }
    
    static var transferRepresentation: some TransferRepresentation {
        let rep = DataRepresentation<CharacterPNGExporter>(exportedContentType: .png) { trans in
            guard var avatar = trans.character.avatar else { return Data() }
            return avatar
        }
        return rep.suggestedFileName { obj in obj.suggestedFileName }
    }
    var suggestedFileName: String { "\(character.name).png" }

}
