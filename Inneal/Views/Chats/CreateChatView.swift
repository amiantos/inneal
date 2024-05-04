//
//  CreateChatView.swift
//  Inneal
//
//  Created by Brad Root on 3/25/24.
//

import SwiftData
import SwiftUI
import UIKit

struct CreateChatView: View {
    @Environment(\.dismiss) var dismiss
    @State var chatName: String = ""
    @State var userName: String = ""
    @Environment(\.modelContext) var modelContext
    @Query(sort: [SortDescriptor(\Character.name)]) var characters: [Character]
    @State var selectedCharacters: Set<Character> = Set<Character>()

    let columns = [
        GridItem(.adaptive(minimum: 150))
    ]

    var body: some View {
        NavigationStack {
            VStack {
                TextField("Your Name (Default: \(Preferences.standard.defaultName))", text: $userName)
                    .textFieldStyle(.roundedBorder)
#if os(iOS)
                    .scrollDismissesKeyboard(.immediately)
#endif
                    .padding([.leading, .trailing])
                ScrollView {
                    //                    TextField("Chat Name (Optional)", text: $chatName)
                    //                        .textFieldStyle(.roundedBorder)
                    //                        .scrollDismissesKeyboard(.immediately)
                    //                        .padding([.top, .leading, .trailing])
                    LazyVGrid(columns: columns, alignment: .center) {
                        ForEach(characters) { character in
                            Button(action: {
                                selectCharacter(character)
                            }, label: {
                                VStack(alignment: .leading) {
                                    Rectangle()
                                        .aspectRatio(2/3, contentMode: .fill)
                                        .foregroundColor(.clear)
                                        .overlay {
                                            if let avatar = character.avatar, let uiImage = UIImage(data: avatar) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .saturation(selectedCharacters.contains(character) ? 1 : 0)
                                                    .colorMultiply(selectedCharacters.contains(character) ? .accentColor : .white)
                                            }
                                        }
                                        .clipped()
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
            }
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", role: .destructive) {
                        dismiss()
                    }.foregroundStyle(.red)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        if !selectedCharacters.isEmpty {
                            guard let characterNames = selectedCharacters.compactMap({ $0.name }) as? [String] else { return }
                            let chatName = characterNames.joined(separator: " & ")
                            Log.debug("Chat Name \(chatName)")

                            let chat = Chat(name: chatName, characters: Array(selectedCharacters))
                            if !userName.isEmpty {
                                chat.userName = userName
                            }
                            modelContext.insert(chat)
                            selectedCharacters.forEach { character in
                                let message = ChatMessage(
                                    content: character.firstMessage,
                                    fromUser: false,
                                    chat: chat,
                                    character: character
                                )
                                modelContext.insert(message)

                                character.alternateGreetings.forEach { greeting in
                                    let contentAlternate = ContentAlternate(string: greeting, message: message)
                                    modelContext.insert(contentAlternate)
                                }
                            }

                            dismiss()
                        }
                    }.disabled(selectedCharacters.isEmpty)
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
}

#Preview {
    CreateChatView().modelContainer(PreviewDataController.previewContainer)
}
