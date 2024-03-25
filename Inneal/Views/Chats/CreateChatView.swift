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
    @State private var selectedCharacter: Character? = nil

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
                                selectedCharacter = character
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
                                                    .saturation(selectedCharacter != character ? 1 : 0)
                                                    .colorMultiply(selectedCharacter != character ? .white : .accentColor)
                                            }
                                        }
                                        .clipped()
                                    Rectangle()
                                        .foregroundColor(.clear)
                                        .aspectRatio(3, contentMode: .fill)
                                        .overlay {
                                            HStack(alignment: .center) {
                                                Image(systemName: selectedCharacter == character ? "checkmark.circle.fill" : "circle")
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
                        if let character = selectedCharacter {
                            let chatNameValidated = chatName.isEmpty ? nil : chatName
                            let chat = Chat(name: chatNameValidated, characters: [character])
                            if !userName.isEmpty {
                                chat.userName = userName
                            }
                            modelContext.insert(chat)
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

                            dismiss()
                        }
                    }.disabled(selectedCharacter == nil)
                }
            }
        }
    }
}

#Preview {
    CreateChatView().modelContainer(PreviewDataController.previewContainer)
}
