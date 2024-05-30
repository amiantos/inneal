//
//  CharacterView.swift
//  Inneal
//
//  Created by Brad Root on 4/4/24.
//

import PhotosUI
import SwiftData
import SwiftUI

struct CharacterView: View {
    @State private var avatarItem: PhotosPickerItem?
    @State private var avatarImage: Image?
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Bindable var character: Character
    @State var showingAlert = false
    @State var showingWarningAlert = false
    @State var newCharacterMode = false
    @State var showingHelpSheet = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Information"), footer: Text("Describe the character and the universe they reside in. This description will be sent with every request, so it will be the main thing that controls the personality of your character. Use {{char}} as a place holder for your character's name, if you intend for it to be changeable by the user.")) {
                    TextField("Character Name", text: $character.name, axis: .vertical)
                        .lineLimit(1)
                    #if !os(macOS)
                        .keyboardType(.asciiCapable)
                    #endif
                    TextField("Description", text: $character.characterDescription, axis: .vertical)
                        .lineLimit(20)
    #if !os(macOS)
                        .keyboardType(.asciiCapable)
                    #endif
                }

                Section(header: Text("Greeting / First Message"), footer: Text("The first message sets the tone for the entire chat, and is highly influential to the personality and behavior of your character. As the chat grows, this will be discarded to make room for chat history.")) {
                    TextField("First Message", text: $character.firstMessage, axis: .vertical)
                        .lineLimit(20)
#if !os(macOS)
                        .keyboardType(.asciiCapable)
                    #endif
                }

                Section(header: Text("Alternate Greetings / First Messages"), footer: Text("Alternate greetings allow you to create multiple different scenarios for one character card. Most people use these to create chats that progress a story in some way, like episodes in the story arc of a television series.")) {
                    ForEach($character.alternateGreetings, id: \.self) { string in
                        NavigationLink(destination: TextEditorView(text: string)) {
                            Text(string.wrappedValue.isEmpty ? "Empty Greeting! Tap to add content." : string.wrappedValue)
                        }
                    }
                    .onDelete(perform: deleteGreeting)
                    .onMove(perform: moveGreeting)

                    Button(action: addGreeting) {
                        Label("Add Greeting", systemImage: "plus")
                    }
                }

                Section(header: Text("Avatar"), footer: Text("Traditionally character cards are 2x3 portrait orientation.")) {
                    VStack {
                        PhotosPicker("Select avatar", selection: $avatarItem, matching: .images)
                        avatarImage?
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 300)
                    }
                }
                .onChange(of: avatarItem) {
                    Task {
                        if let loaded = try? await avatarItem?.loadTransferable(type: Image.self),
                           let data = try? await avatarItem?.loadTransferable(type: Data.self)
                        {
                            avatarImage = loaded
                            character.avatar = data
                        } else {
                            Log.debug("Failed")
                        }
                    }
                }

                Section(header: Text("Other Attributes"), footer: Text("Example dialogues should include {{user}}: and {{char}}: as prefixes.")) {
                    TextField("Scenario (Optional)", text: $character.scenario, axis: .vertical)
                        .lineLimit(20)
#if !os(macOS)
                        .keyboardType(.asciiCapable)
                    #endif
                    TextField("Personality (Optional)", text: $character.personality, axis: .vertical)
                        .lineLimit(20)
#if !os(macOS)
                        .keyboardType(.asciiCapable)
                    #endif
                    TextField("Example Messages (Optional)", text: $character.exampleMessage, axis: .vertical)
                        .lineLimit(20)
#if !os(macOS)
                        .keyboardType(.asciiCapable)
                    #endif
                }

                Section(header: Text("Metadata")) {
                    TextField("Creator Name", text: $character.creator, axis: .vertical)
                        .lineLimit(1)
#if !os(macOS)
                        .keyboardType(.asciiCapable)
                    #endif
                    TextField("Creator Notes (Optional)", text: $character.creatorNotes, axis: .vertical)
                        .lineLimit(20)
#if !os(macOS)
                        .keyboardType(.asciiCapable)
                    #endif
                }

                Section(header: Text("Prompt Engineering")) {
                    TextField("System Prompt (Optional)", text: $character.systemPrompt, axis: .vertical)
                        .lineLimit(20)
#if !os(macOS)
                        .keyboardType(.asciiCapable)
                    #endif
                    TextField("Post-History Instructions (Optional)", text: $character.postHistoryInstructions, axis: .vertical)
                        .lineLimit(20)
#if !os(macOS)
                        .keyboardType(.asciiCapable)
                    #endif
                }

                if !newCharacterMode {
                    Button("Delete Character", role: .destructive) {
                        showingAlert = true
                    }
                    .alert("Delete Character?", isPresented: $showingAlert) {
                        Button("OK", role: .destructive) {
                            modelContext.delete(character)
                            dismiss()
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("Deleting characters is not recoverable. Any chat featuring this character will be deleted as well. Are you sure you want to do this?\n\n\(character.name) told me to tell you that they will be sad and will miss you. 🥺")
                    }
                }
            }
            .navigationTitle(Text(newCharacterMode ? "New Character" : "Editing \(character.name)"))
            .toolbar {
                if newCharacterMode {
                    ToolbarItemGroup(placement: .cancellationAction) {
                        Button("Cancel", role: .destructive) {
                            showingWarningAlert.toggle()
                        }
                        .foregroundStyle(.red)
                        .alert("Cancel New Character?", isPresented: $showingWarningAlert) {
                            Button("OK", role: .destructive) {
                                dismiss()
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("Are you sure you want to cancel? This new character will be lost if you do not save it.")
                        }
                    }

                    ToolbarItemGroup(placement: .primaryAction) {
                        Button("Help", systemImage: "questionmark.circle") {
                            showingHelpSheet.toggle()
                        }
                        Button {
                            Log.debug("Save?")
                            modelContext.insert(character)
                            dismiss()
                        } label: {
                            Text("Save")
                        }
                    }
                } else {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Help", systemImage: "questionmark.circle") {
                            showingHelpSheet.toggle()
                        }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                if let avatar = character.avatar, let uiImage = InnealImage(data: avatar) {
                    avatarImage = Image(innealImage: uiImage)
                }
            }
            .sheet(isPresented: $showingHelpSheet) {
                CharacterHelpView()
            }
        }
    }

    private func addGreeting() {
        character.alternateGreetings.append("")
    }

    private func deleteGreeting(at offsets: IndexSet) {
        character.alternateGreetings.remove(atOffsets: offsets)
    }

    private func moveGreeting(from source: IndexSet, to destination: Int) {
        character.alternateGreetings.move(fromOffsets: source, toOffset: destination)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Character.self, configurations: config)
    let character = Character(
        name: "Bradley Root",
        characterDescription: "Bradley is a software engineer",
        personality: "",
        firstMessage: "Hi! I'm Bradley!",
        exampleMessage: "",
        scenario: "",
        creatorNotes: "",
        systemPrompt: "",
        postHistoryInstructions: "",
        alternateGreetings: ["Hi, I smell like butt!", "Whoa! Spicy take there buddy. Oh, I didn't see you there."],
        tags: [],
        creator: "Brad Root",
        characterVersion: "main",
        chubId: "",
        avatar: UIImage(named: "brad-real")!.pngData()!
    )
    container.mainContext.insert(character)
    return NavigationStack {
        CharacterView(character: character)
            .modelContainer(container)
            .navigationTitle("Edit Character")
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Character.self, configurations: config)
    let character = Character(
        name: "Bradley Root",
        characterDescription: "Bradley is a software engineer",
        personality: "",
        firstMessage: "Hi! I'm Bradley!",
        exampleMessage: "",
        scenario: "",
        creatorNotes: "",
        systemPrompt: "",
        postHistoryInstructions: "",
        alternateGreetings: ["Hi, I smell like butt!", "Whoa! Spicy take there buddy. Oh, I didn't see you there."],
        tags: [],
        creator: "Brad Root",
        characterVersion: "main",
        chubId: "",
        avatar: UIImage(named: "brad-real")!.pngData()!
    )
    container.mainContext.insert(character)
    return NavigationStack {
        CharacterView(character: character, newCharacterMode: true)
            .modelContainer(container)
            .navigationTitle("Edit Character")
    }
}
