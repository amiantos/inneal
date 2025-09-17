//
//  PreviewDataController.swift
//  Inneal
//
//  Created by Brad Root on 4/5/24.
//

import Foundation
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

@MainActor
enum PreviewDataController {
    static let previewContainer: ModelContainer = {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: Chat.self, Character.self, APIConfiguration.self, configurations: config)
            let nameChoices = ["Kuroho", "Marcus Tulluis Cicero", "Marin", "Aunt Catherine and the Seven Catgirls", "The Kingdom's Finest", "Dreamlands", "Seraphina", "Amiantos"]
            let imageNameChoices = ["brad-drawn", "cicero", "dreamlands", "kuroho", "seraphina"]
            var characters: [Character] = []
            for x in 1 ..< 10 {
                let character = Character(name: nameChoices.randomElement()!, characterDescription: "Bradley is a software engineer", personality: "", firstMessage: "Hi! I'm Bradley!", exampleMessage: "", scenario: "", creatorNotes: "", systemPrompt: "", postHistoryInstructions: "", alternateGreetings: [], tags: [], creator: "Brad Root", characterVersion: "main", chubId: "", avatar: UIImage(named: imageNameChoices.randomElement()!)!.pngData()!)
                container.mainContext.insert(character)
                characters.append(character)
            }
            for i in 1 ..< 20 {
                let character = characters.randomElement()!
                let chat = Chat(name: "\(character.name)", characters: [character])
                container.mainContext.insert(chat)
                for i in 1 ..< 10 {
                    let message = ChatMessage(content: "Lorem ipsum dolor sit amet. {{user}}? {{char}}? {{User}}? {{Char}}? consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.", fromUser: [true, false].randomElement()!, chat: chat, character: character)
                    container.mainContext.insert(message)
                }
            }
            return container
        } catch {
            fatalError("Failed to create model container for previewing: \(error.localizedDescription)")
        }
    }()
}
