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
    @State private var isImporting = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Import Character"), footer: Text("• Chub.ai / Venus character URL or ID\n• Pygmalion.chat character URL\n• Link to a Tavern character card PNG\n• JSON character data\n• Link to a JSON file")) {
                    HStack {
                        Text("Paste a String")
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
                ToolbarItem(placement: .navigation) {
                    Button("Cancel", role: .destructive) {
                        dismiss()
                    }.foregroundStyle(.red)
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        isImporting = true
                    } label: {
                        Label("Import file", systemImage: "square.and.arrow.down")
                    }
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
                Text("Imported content was not recongized as an importable object. Try again?")
            }
            .fileImporter(isPresented: $isImporting,
                          allowedContentTypes: [.json, .png]) {
                let result = $0.flatMap { url in
                  read(from: url)
                }
                switch result {
                case .success(let data):
                    Task {
                        await viewModel.loadFromImported(data)
                    }
                case .failure(let error):
                    Log.debug(error)
                }
              }
        }
    }

    private func read(from url: URL) -> Result<Data,Error> {
      let accessing = url.startAccessingSecurityScopedResource()
      defer {
        if accessing {
          url.stopAccessingSecurityScopedResource()
        }
      }

      return Result { try Data(contentsOf: url) }
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
            } else if string.contains(".json") {
                await loadJSON(for: string)
            } else {
                await tryLoading(string)
            }
        }

        fileprivate func tryLoading(_ string: String) async {
            return await loadJSONfromData(string.data(using: .utf8)!)

        }

        func loadFromImported(_ data: Data) async {
            if UIImage(data: data) != nil {
                return await loadData(from: data)
            } else {
                return await loadJSONfromData(data)
            }
        }

        fileprivate func loadJSONfromData(_ data: Data) async {
            do {
                let decodedResponse = try JSONDecoder().decode(TavernData.self, from: data)
                return try await character(for: decodedResponse)
            } catch {
                Log.debug("\(error)")
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(TavernCharacterData.self, from: data)
                return try await character(for: decodedResponse)
            } catch {
                Log.debug("\(error)")
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(TavernOne.self, from: data)
                return try character(for: decodedResponse)
            } catch {
                Log.debug("\(error)")
            }

            showErrorAlert.toggle()
        }
        
        func loadJSON(for urlString: String) async {
            do {
                let request = URLRequest(url: URL(string: urlString)!)
                let (data, response) = try await URLSession.shared.data(for: request)
                if let response = response as? HTTPURLResponse {
                    if (200 ..< 300) ~= response.statusCode {
                        await loadJSONfromData(data)
                    }
                }
            } catch {
                Log.debug("\(error)")
            }
        }

        func character(for tavernOne: TavernOne) throws {
            name = tavernOne.charName.isEmpty ? tavernOne.name : tavernOne.charName
            description = tavernOne.charPersona.isEmpty ? tavernOne.description : tavernOne.charPersona
            firstMessage = tavernOne.charGreeting.isEmpty ? tavernOne.firstMes : tavernOne.charGreeting
            exampleMessages = tavernOne.exampleDialog.isEmpty ? tavernOne.mesExample : tavernOne.exampleDialog
            scenario = tavernOne.worldScenario.isEmpty ? tavernOne.scenario : tavernOne.worldScenario
            alternateGreetings = []
            tags = []
            personality = ""
            creatorNotes = ""
            systemPrompt = ""
            postHistoryInstructions = ""
            creator = ""
            characterVersion = ""
            avatar = nil
            characterIsImportable = true
        }

        func character(for tavernData: TavernData) async throws {
            name = tavernData.data.name
            description = tavernData.data.description
            firstMessage = tavernData.data.firstMes
            scenario = tavernData.data.scenario
            exampleMessages = tavernData.data.mesExample
            alternateGreetings = tavernData.data.alternateGreetings
            tags = tavernData.data.tags
            characterIsImportable = true
            personality = tavernData.data.personality
            creatorNotes = tavernData.data.creatorNotes
            systemPrompt = tavernData.data.systemPrompt
            postHistoryInstructions = tavernData.data.postHistoryInstructions
            creator = tavernData.data.creator
            characterVersion = tavernData.data.characterVersion

            let imageRequest = URLRequest(url: URL(string: tavernData.data.avatar)!)
            let (imageData, imageResponse) = try await URLSession.shared.data(for: imageRequest)
            if let imageResponse = imageResponse as? HTTPURLResponse {
                if (200 ..< 300) ~= imageResponse.statusCode {
                    avatar = imageData
                }
            }
        }

        func character(for tavernCharacterData: TavernCharacterData) async throws {
            name = tavernCharacterData.name
            description = tavernCharacterData.description
            firstMessage = tavernCharacterData.firstMes
            scenario = tavernCharacterData.scenario
            exampleMessages = tavernCharacterData.mesExample
            alternateGreetings = tavernCharacterData.alternateGreetings
            tags = tavernCharacterData.tags
            characterIsImportable = true
            personality = tavernCharacterData.personality
            creatorNotes = tavernCharacterData.creatorNotes
            systemPrompt = tavernCharacterData.systemPrompt
            postHistoryInstructions = tavernCharacterData.postHistoryInstructions
            creator = tavernCharacterData.creator
            characterVersion = tavernCharacterData.characterVersion

            let imageRequest = URLRequest(url: URL(string: tavernCharacterData.avatar)!)
            let (imageData, imageResponse) = try await URLSession.shared.data(for: imageRequest)
            if let imageResponse = imageResponse as? HTTPURLResponse {
                if (200 ..< 300) ~= imageResponse.statusCode {
                    avatar = imageData
                }
            }
        }

        func loadPng(for urlString: String) async {
            do {
                let request = URLRequest(url: URL(string: urlString)!)
                let (data, response) = try await URLSession.shared.data(for: request)
                if let response = response as? HTTPURLResponse {
                    if (200 ..< 300) ~= response.statusCode {
                        return await loadData(from: data)
                    }
                }
            } catch {
                Log.debug("\(error)")
            }
            showErrorAlert.toggle()
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
                return
            } catch {
                Log.debug("\(error)")
            }
            showErrorAlert.toggle()
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
                        return await loadData(from: data)
                    }
                }

            } catch {
                Log.debug("\(error)")
            }
            showErrorAlert.toggle()
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
                avatar: avatar
            )
            return character
        }
    }
}
