//
//  CreateChatView.swift
//  Inneal
//
//  Created by Brad Root on 3/25/24.
//

import SwiftData
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct CreateChatView: View {
    @Environment(\.dismiss) var dismiss
    @State var chatName: String = ""
    @State var userName: String = ""
    @Environment(\.modelContext) var modelContext
    @Query(sort: [SortDescriptor(\Character.name)]) var characters: [Character]
    @State var selectedCharacters: Set<Character> = .init()
    @State var showingWarningAlert = false

    let columns = [
        GridItem(.adaptive(minimum: 150)),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, alignment: .center) {
                    ForEach(characters) { character in
                        Button(action: {
                            selectCharacter(character)
                        }, label: {
                            VStack(alignment: .leading) {
                                Rectangle()
                                    .aspectRatio(2 / 3, contentMode: .fill)
                                    .foregroundColor(.clear)
                                    .overlay {
                                        if let avatar = character.avatar, let uiImage = InnealImage(data: avatar) {
                                            Image(innealImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                        } else {
                                            Image(systemName: "face.smiling")
                                                .resizable()
                                                .scaledToFit()
                                                .padding()
                                                .colorMultiply(selectedCharacters.contains(character) ? .accentColor : .white)
                                        }
                                    }
                                    .clipped()
                                    .saturation(selectedCharacters.contains(character) ? 1 : 0)
                                Rectangle()
                                    .foregroundColor(.clear)
                                    .aspectRatio(3, contentMode: .fill)
                                    .overlay {
                                        HStack(alignment: .center) {
                                            Image(systemName: selectedCharacters.contains(character) ? "checkmark.circle.fill" : "circle")
                                                .resizable()
                                                .frame(width: 22, height: 22)
                                                .foregroundStyle(.accent)
                                                .padding(.leading)
                                            Text(character.name)
                                                .lineLimit(2)
                                                .font(.subheadline)
                                                .minimumScaleFactor(0.5)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(.trailing)
                                                .padding(.leading, 3)
                                        }
                                        .padding(.bottom, 5)
                                    }
                            }
                        })
                        .buttonStyle(.plain)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 12.0))
                    }
                }
                .padding()
                #if os(iOS)
                    .scrollDismissesKeyboard(.immediately)
                #endif
            }
            .navigationTitle("New Chat")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .destructive) {
                        dismiss()
                    }.foregroundStyle(.red)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        tryCreateChat()
                    }
                    .disabled(selectedCharacters.isEmpty)
                    .alert("Multi-Character Chat", isPresented: $showingWarningAlert) {
                        Button("Groovy") {
                            createChat()
                        }
                        Button("Nevermind", role: .cancel) {}
                    } message: {
                        Text("When a multi-character chat is created, it is populated with all of the character's first messages. Delete or edit the messages to set the scenario you want.")
                    }
                }
            }
        }
    }

    func selectCharacter(_ character: Character) {
        if selectedCharacters.contains(character) {
            selectedCharacters.remove(character)
        } else {
            selectedCharacters.insert(character)
        }
    }

    fileprivate func tryCreateChat() {
        if !selectedCharacters.isEmpty {
            if selectedCharacters.count > 1 {
                showingWarningAlert.toggle()
            } else {
                createChat()
            }
        }
    }

    fileprivate func createChat() {
        if !selectedCharacters.isEmpty {
            guard let characterNames = selectedCharacters.compactMap({ $0.name }) as? [String] else { return }
            let chatName = characterNames.joined(separator: " & ")
            Log.debug("Chat Name \(chatName)")

            let chat = Chat(name: chatName, characters: Array(selectedCharacters))
            if !userName.isEmpty {
                chat.userName = userName
            }
            modelContext.insert(chat)
            for character in selectedCharacters {
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
            }

            dismiss()
        }
    }
}

#Preview {
    CreateChatView().modelContainer(PreviewDataController.previewContainer)
}
