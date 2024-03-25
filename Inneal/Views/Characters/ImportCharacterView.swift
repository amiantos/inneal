//
//  ImportCharacterView.swift
//  Inneal
//
//  Created by Brad Root on 4/4/24.
//

import SwiftUI
import UIKit

struct ImportCharacterView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @State var viewModel = ImportCharacterView.ViewModel()
    @State var lastImportStringAttempt: String?

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Import Character"), footer: Text("Use that Paste button to paste in a variety of things, such as...\n\n• Chub.ai / Venus Character URL or ID\n• Pygmalion.chat Character URL\n• Link to a Tavern character card PNG")) {
                    HStack {
                        Text("Paste a URL")
                        Spacer()
                        PasteButton(payloadType: String.self) { strings in
                            guard let first = strings.first else { return }
                            lastImportStringAttempt = first
                            Task {
                                await viewModel.detectTypeAndImport(string: first)
                            }
                        }
                    }
                }

                Section("Name Preview") {
                    Text(viewModel.name)
                }
                Section("Description Preview") {
                    Text(!viewModel.description.isEmpty ? "\(viewModel.description.prefix(500))..." : "")
                }
                Section("Image Preview") {
                    if let image = viewModel.avatar {
                        Image(uiImage: UIImage(data: image)!).resizable().scaledToFit()
                    } else {
                        Text("")
                    }
                }
            }
            .navigationTitle("Import Character")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", role: .destructive) {
                        dismiss()
                    }.foregroundStyle(.red)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        let character = viewModel.getCharacter()
                        modelContext.insert(character)
                        dismiss()
                    }.disabled(!viewModel.characterIsImportable)
                }
            }
            .alert("Unrecongized Import", isPresented: $viewModel.showErrorAlert) {
                Button("OK") {}
            } message: {
                if let lastImportStringAttempt {
                    Text("Imported text \"\(lastImportStringAttempt)\" was not recongized as an importable URL. Try again?")
                } else {
                    Text("Unknown error occurred, try again?")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ImportCharacterView().modelContainer(PreviewDataController.previewContainer)
    }
}

extension ImportCharacterView {
    @Observable
    class ViewModel {
        var name: String = ""
        var description: String = ""
        var personality: String = ""
        var firstMessage: String = ""
        var scenario: String = ""
        var exampleMessages: String = ""
        var alternateGreetings: [String] = []
        var tags: [String] = []
        var avatar: Data?
        var characterIsImportable: Bool = false
        var creatorNotes: String = ""
        var systemPrompt: String = ""
        var postHistoryInstructions: String = ""
        var creator: String = ""
        var chubId: String = ""
        var characterVersion: String = ""
        var showErrorAlert: Bool = false

        func detectTypeAndImport(string: String) async {
            if string.contains("chub.ai") {
                await loadTavernImageUrlString(for: string)
            } else if string.contains("pygmalion.chat") {
                await loadPygmalionChatCharacter(for: string)
            } else if string.contains(".png") {
                await loadPng(for: string)
            } else {
                showErrorAlert.toggle()
            }
        }

        func loadPng(for urlString: String) async {
            do {
                let request = URLRequest(url: URL(string: urlString)!)
                let (data, response) = try await URLSession.shared.data(for: request)
                if let response = response as? HTTPURLResponse {
                    if (200 ..< 300) ~= response.statusCode {
                        await loadData(from: data)
                    }
                }
            } catch {
                Log.debug("\(error)")
            }
        }

        func loadPygmalionChatCharacter(for urlString: String) async {
            let pygmalionCharacterId = urlString.replacingOccurrences(of: "https://pygmalion.chat/character/", with: "").replacingOccurrences(of: "https://www.pygmalion.chat/character/", with: "").replacingOccurrences(of: "https://venus.chub.ai/characters/", with: "")

            var request = URLRequest(url: URL(string: "https://server.pygmalion.chat/api/export/character/\(pygmalionCharacterId)/v2")!)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Inneal:1.0:https://amiantos.net", forHTTPHeaderField: "Client-Agent")
            Log.debug("Requesting character from API...")
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if let response = response as? HTTPURLResponse {
                    if (200 ..< 300) ~= response.statusCode {
                        let decodedResponse = try JSONDecoder().decode(PygmalionChatCharacterResponse.self, from: data)
                        name = decodedResponse.character.data.name
                        description = decodedResponse.character.data.description
                        firstMessage = decodedResponse.character.data.firstMes
                        scenario = decodedResponse.character.data.scenario
                        exampleMessages = decodedResponse.character.data.mesExample
                        alternateGreetings = decodedResponse.character.data.alternateGreetings
                        tags = decodedResponse.character.data.tags
                        characterIsImportable = true
                        personality = decodedResponse.character.data.personality
                        creatorNotes = decodedResponse.character.data.creatorNotes
                        systemPrompt = decodedResponse.character.data.systemPrompt
                        postHistoryInstructions = decodedResponse.character.data.postHistoryInstructions
                        creator = decodedResponse.character.data.creator
                        characterVersion = decodedResponse.character.data.characterVersion

                        let imageRequest = URLRequest(url: URL(string: decodedResponse.character.data.avatar)!)
                        let (imageData, imageResponse) = try await URLSession.shared.data(for: imageRequest)
                        if let imageResponse = imageResponse as? HTTPURLResponse {
                            if (200 ..< 300) ~= imageResponse.statusCode {
                                avatar = imageData
                            }
                        }
                    }
                }

            } catch {
                Log.debug("\(error)")
            }

        }



        func loadTavernImageUrlString(for characterId: String) async {
            chubId = characterId
            if chubId.contains("https://") {
                chubId = chubId.replacingOccurrences(of: "https://chub.ai/characters/", with: "").replacingOccurrences(of: "https://www.chub.ai/characters/", with: "")
            }

            var request = URLRequest(url: URL(string: "https://api.chub.ai/api/characters/download")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Inneal:1.0:https://amiantos.net", forHTTPHeaderField: "Client-Agent")

            let params = ChubAPICharacterRequest(format: "tavern", fullPath: chubId, version: "main")
            let encodedParameters = try? JSONEncoder().encode(params)
            request.httpBody = encodedParameters

            Log.debug("Requesting character from API...")
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if let response = response as? HTTPURLResponse {
                    if (200 ..< 300) ~= response.statusCode {
                        await loadData(from: data)
                    }
                }

            } catch {
                Log.debug("\(error)")
            }
        }

        func loadData(from data: Data) async {
            let (imageData, image) = await readPNGTextChunks(from: data)
            if let imageData = imageData, let image = image {
                name = imageData.name
                description = imageData.description
                firstMessage = imageData.firstMes
                scenario = imageData.scenario
                exampleMessages = imageData.mesExample
                alternateGreetings = imageData.alternateGreetings
                tags = imageData.tags
                avatar = image
                characterIsImportable = true
                personality = imageData.personality
                creatorNotes = imageData.creatorNotes
                systemPrompt = imageData.systemPrompt
                postHistoryInstructions = imageData.postHistoryInstructions
                creator = imageData.creator
                characterVersion = imageData.characterVersion
            }
        }

        func getCharacter() -> Character {
            let character = Character(
                name: name,
                characterDescription: description,
                personality: personality,
                firstMessage: firstMessage,
                exampleMessage: exampleMessages,
                scenario: scenario,
                creatorNotes: creatorNotes,
                systemPrompt: systemPrompt,
                postHistoryInstructions: postHistoryInstructions,
                alternateGreetings: alternateGreetings,
                tags: tags,
                creator: creator,
                characterVersion: characterVersion,
                chubId: chubId,
                avatar: avatar!
            )
            return character
        }
    }
}
