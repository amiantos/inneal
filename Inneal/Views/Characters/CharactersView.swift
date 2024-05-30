//
//  CharactersView.swift
//  Inneal
//
//  Created by Brad Root on 4/4/24.
//

import Combine
import SwiftData
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct CharactersView: View {
    @Environment(\.dismiss) var dismiss
    @Query(sort: [SortDescriptor(\Character.name)]) var characters: [Character]
    @Environment(\.modelContext) var modelContext
    @State private var showingSheet = false
    @State private var showingNewCharacterSheet = false
    @State private var selectedCharacter: Character?

    let columns = [
        GridItem(.adaptive(minimum: 150)),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, alignment: .center) {
                    ForEach(characters) { character in
                        Menu {
                            Button {
                                createNewChat(character)
                            } label: {
                                Label("New Chat", systemImage: "plus")
                            }

                            Divider()

                            Button {
                                selectedCharacter = character
                            } label: {
                                Label("Edit Character", systemImage: "square.and.pencil")
                            }

                            Button {
                                duplicateCharacter(character)
                            } label: {
                                Label("Duplicate Character", systemImage: "doc.on.doc")
                            }

                            Divider()

                            Button {
                                copyJSON(character)
                            } label: {
                                Label("Copy as JSON", systemImage: "doc.on.doc")
                            }

                            Divider()

                            Group {
                                if let avatar = character.avatar, let uiImage = UIImage(data: avatar) {
                                    ShareLink(item: character, preview: SharePreview("\(character.name).json", image: Image(uiImage: uiImage))) {
                                        Label("Share as JSON", systemImage: "square.and.arrow.up")
                                    }
                                } else {
                                    ShareLink(item: character, preview: .init("Share JSON")) {
                                        Label("Share as JSON", systemImage: "square.and.arrow.up")
                                    }
                                }
                            }

                            Group {
                                if let avatar = character.avatar, let uiImage = UIImage(data: avatar) {
                                    ShareLink(item: CharacterPNGExporter(character: character), preview: SharePreview("\(character.name).png", image: Image(uiImage: uiImage))) {
                                        Label("Share Avatar", systemImage: "square.and.arrow.up")
                                    }
                                }
                            }
                        } label: {
                            VStack(alignment: .leading) {
                                Rectangle()
                                    .aspectRatio(2 / 3, contentMode: .fill)
                                    .foregroundColor(.clear)
                                    .overlay {
                                        if let avatar = character.avatar, let uiImage = UIImage(data: avatar) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                        } else {
                                            Image(systemName: "face.smiling")
                                                .resizable()
                                                .scaledToFit()
                                                .padding()
                                        }
                                    }
                                    .clipped()
                                Rectangle()
                                    .foregroundColor(.clear)
                                    .aspectRatio(3, contentMode: .fill)
                                    .overlay {
                                        HStack(alignment: .center) {
                                            Text(character.name)
                                                .lineLimit(2)
                                                .font(.subheadline)
                                                .minimumScaleFactor(0.5)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(.leading)
                                                .padding(.trailing)
                                        }
                                        .padding(.bottom, 5)
                                    }
                            }
                        }
                        .buttonStyle(.plain)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 12.0))
                    }
                }
                .padding()
            }
            .navigationTitle("\(characters.count) Characters")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        showingSheet.toggle()
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                    Button {
                        selectedCharacter = nil
                        showingNewCharacterSheet.toggle()
                    } label: {
                        Label("Create", systemImage: "square.and.pencil")
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                }
            }
        }
        .sheet(isPresented: $showingSheet) {
            ImportCharacterView()
        }
        .sheet(item: $selectedCharacter, content: { character in
            CharacterView(character: character)
                .interactiveDismissDisabled()
        })
        .sheet(isPresented: $showingNewCharacterSheet) {
            let newCharacter = Character(name: "", characterDescription: "", personality: "", firstMessage: "", exampleMessage: "", scenario: "", creatorNotes: "", systemPrompt: "", postHistoryInstructions: "", alternateGreetings: [], tags: [], creator: "", characterVersion: "main", chubId: "")
            CharacterView(character: newCharacter, newCharacterMode: true)
                .interactiveDismissDisabled()
        }
    }

    func copyJSON(_ character: Character) {
        let tavernData = TavernData(data: TavernCharacterData(name: character.name, description: character.characterDescription, personality: character.personality, firstMes: character.firstMessage, avatar: "", mesExample: character.exampleMessage, scenario: character.scenario, creatorNotes: character.creatorNotes, systemPrompt: character.systemPrompt, postHistoryInstructions: character.postHistoryInstructions, alternateGreetings: character.alternateGreetings, tags: character.tags, creator: character.creator, characterVersion: character.characterVersion), spec: "chara_card_v2", specVersion: "2.0")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let jsonData = try encoder.encode(tavernData)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                UIPasteboard.general.string = jsonString
            }
        } catch {
            Log.error("Error encoding JSON: \(error)")
        }
    }

    func exportPNG(_: Character) {
        // TODO:
    }

    func createNewChat(_ character: Character) {
        let chat = Chat(name: nil, characters: [character])
        modelContext.insert(chat)
        let message = ChatMessage(
            content: character.firstMessage,
            fromUser: false,
            chat: chat,
            character: character
        )
        modelContext.insert(message)
        for greeting in character.alternateGreetings {
            let contentAlternate = ContentAlternate(string: greeting, message: message)
            modelContext.insert(contentAlternate)
        }

        dismiss()
    }

    func duplicateCharacter(_ character: Character) {
        let newCharacter = Character(
            name: "\(character.name) (Copy)",
            characterDescription: character.characterDescription,
            personality: character.personality,
            firstMessage: character.firstMessage,
            exampleMessage: character.exampleMessage,
            scenario: character.scenario,
            creatorNotes: character.creatorNotes,
            systemPrompt: character.systemPrompt,
            postHistoryInstructions: character.postHistoryInstructions,
            alternateGreetings: character.alternateGreetings,
            tags: character.tags,
            creator: character.creator,
            characterVersion: character.characterVersion,
            chubId: character.chubId,
            avatar: character.avatar
        )
        modelContext.insert(newCharacter)
    }
}

#Preview {
    NavigationStack {
        CharactersView()
            .modelContainer(PreviewDataController.previewContainer)
            .navigationTitle("Characters")
    }
}
