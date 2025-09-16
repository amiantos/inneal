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
    @State var selectedCharacters: Set<Character> = .init()
    @State var showingWarningAlert = false
    let onNewItem: ([Character]) -> Void

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
                                        if let avatar = character.avatar, let uiImage = UIImage(data: avatar) {
                                            Image(uiImage: uiImage)
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
            onNewItem(selectedCharacters.sorted { $0.name < $1.name })
            dismiss()
        }
    }
}

#Preview {
    CreateChatView(onNewItem: { blah in
    print(blah)}).modelContainer(PreviewDataController.previewContainer)
}

