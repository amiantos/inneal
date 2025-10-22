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
    @State private var characterToDelete: Character?
    @State private var showingDeleteAlert: Bool = false
    @Namespace var buttonUnionNamespace
    let onNewItem: ([Character]) -> Void

    let columns = [
        GridItem(.adaptive(minimum: 150))
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, alignment: .center) {
                    ForEach(characters) { character in
                        VStack(alignment: .center) {
                            ZStack(alignment: .bottom) {
                                Rectangle()
                                    .aspectRatio(2 / 3, contentMode: .fill)
                                    .foregroundColor(.clear)
                                    .overlay {
                                        if let avatar = character.avatar,
                                           let uiImage = UIImage(data: avatar)
                                        {
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
                            }
                            Text(character.name)
                                .lineLimit(1)
                                .fontWeight(.bold)
                                .minimumScaleFactor(0.5)
                                .padding(.top, 2)
                                .padding([.leading, .trailing], 8)
                            Divider()
                            HStack {
                                Spacer()
                                Button {
                                    selectedCharacter = character
                                } label: {
                                    Label(
                                        "Edit",
                                        systemImage: "square.and.pencil"
                                    ).padding(5).foregroundStyle(Color.accentColor)
                                }.padding(.bottom, 5)
                                Spacer()
                                Divider()
                                Spacer()
                                Menu {
                                    Button {
                                        createNewChat(character)
                                    } label: {
                                        Label("New Chat", systemImage: "plus")
                                    }
                                    
                                    Divider()
                                    
                                    Button {
                                        copyJSON(character)
                                    } label: {
                                        Label(
                                            "Copy JSON",
                                            systemImage: "doc.on.doc"
                                        )
                                    }
                                    
                                    Group {
                                        if let avatar = character.avatar,
                                           let uiImage = UIImage(data: avatar)
                                        {
                                            ShareLink(
                                                item: CharacterTransferData(
                                                    from: character
                                                ),
                                                preview: SharePreview(
                                                    "\(character.name).json",
                                                    image: Image(
                                                        uiImage: uiImage
                                                    )
                                                )
                                            ) {
                                                Label(
                                                    "Share JSON",
                                                    systemImage:
                                                        "square.and.arrow.up"
                                                )
                                            }
                                        } else {
                                            ShareLink(
                                                item: CharacterTransferData(
                                                    from: character
                                                ),
                                                preview: .init("Share JSON")
                                            ) {
                                                Label(
                                                    "Share JSON",
                                                    systemImage:
                                                        "square.and.arrow.up"
                                                )
                                            }
                                        }
                                    }
                                    
                                    Group {
                                        if let avatar = character.avatar,
                                           let uiImage = UIImage(data: avatar)
                                        {
                                            ShareLink(
                                                item: CharacterPNGExporter(
                                                    character: character
                                                ),
                                                preview: SharePreview(
                                                    "\(character.name).png",
                                                    image: Image(
                                                        uiImage: uiImage
                                                    )
                                                )
                                            ) {
                                                Label(
                                                    "Share Avatar",
                                                    systemImage:
                                                        "square.and.arrow.up"
                                                )
                                            }
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    Button {
                                        selectedCharacter = character
                                    } label: {
                                        Label(
                                            "Edit Character",
                                            systemImage: "square.and.pencil"
                                        )
                                    }
                                    
                                    Button {
                                        duplicateCharacter(character)
                                    } label: {
                                        Label(
                                            "Duplicate Character",
                                            systemImage: "doc.on.doc"
                                        )
                                    }
                                    
                                    Button(role: .destructive) {
                                        deleteCharacter(character)
                                    } label: {
                                        Label(
                                            "Delete Character",
                                            systemImage: "trash"
                                        )
                                    }
                                } label: {
                                    Label("More", systemImage: "ellipsis").labelStyle(.iconOnly).padding(5)
                                }.padding(.bottom, 5).foregroundStyle(Color.accentColor)
                                Spacer()
                                
                            }.buttonStyle(.plain)
                        }
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 12.0))
                    }
                }
                .padding()
            }
            .navigationTitle("\(characters.count) Characters")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.large)
            #endif
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
                    Button("Cancel", systemImage: "xmark") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingSheet) {
            ImportCharacterView()
        }
        .sheet(
            item: $selectedCharacter,
            content: { character in
                CharacterView(character: character)
                    .interactiveDismissDisabled()
            }
        )
        .sheet(isPresented: $showingNewCharacterSheet) {
            let newCharacter = Character(
                name: "",
                characterDescription: "",
                personality: "",
                firstMessage: "",
                exampleMessage: "",
                scenario: "",
                creatorNotes: "",
                systemPrompt: "",
                postHistoryInstructions: "",
                alternateGreetings: [],
                tags: [],
                creator: "",
                characterVersion: "main",
                chubId: ""
            )
            CharacterView(character: newCharacter, newCharacterMode: true)
                .interactiveDismissDisabled()
        }
        .alert("Delete Character?", isPresented: $showingDeleteAlert) {
            Button("OK", role: .destructive) {
                if let character = characterToDelete {
                    modelContext.delete(character)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "Deleting characters is not recoverable. Any chat featuring this character will be deleted as well. Are you sure you want to do this?\n\n\(characterToDelete?.name ?? "Error?!") told me to tell you that they will be sad and will miss you. 🥺"
            )
        }
    }

    func copyJSON(_ character: Character) {
        let tavernData = TavernData(
            data: TavernCharacterData(
                name: character.name,
                description: character.characterDescription,
                personality: character.personality,
                firstMes: character.firstMessage,
                avatar: "",
                mesExample: character.exampleMessage,
                scenario: character.scenario,
                creatorNotes: character.creatorNotes,
                systemPrompt: character.systemPrompt,
                postHistoryInstructions: character.postHistoryInstructions,
                alternateGreetings: character.alternateGreetings,
                tags: character.tags,
                creator: character.creator,
                characterVersion: character.characterVersion
            ),
            spec: "chara_card_v2",
            specVersion: "2.0"
        )
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
        onNewItem([character])
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

    func deleteCharacter(_ character: Character) {
        characterToDelete = character
        showingDeleteAlert = true
    }
}

#Preview {
    NavigationStack {
        CharactersView(onNewItem: { blah in print(blah) })
            .modelContainer(PreviewDataController.previewContainer)
            .navigationTitle("Characters")
    }
}
