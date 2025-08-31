//
//  NewChatView.swift
//  Inneal
//
//  Created by Brad Root on 8/30/25.
//

import SwiftData
import SwiftUI

struct NewChatView: View {
    let chat: Chat
    var userSettings: UserSettings
    var viewModel: ChatView.ViewModel
    @Environment(\.modelContext) var modelContext
    @Query var messages: [ChatMessage]
    @State var newMessage: String = ""
    @Namespace var unionNamespace
    
    init(for chat: Chat, modelContext: ModelContext, userSettings: UserSettings) {
        Log.debug("Init ChatView for \(chat.name)")
        self.chat = chat
        let id = chat.uuid
        _messages = Query(filter: #Predicate { $0.chatUUID == id }, sort: \.dateCreated)
        self.userSettings = userSettings
        viewModel = ChatView.ViewModel(for: chat, modelContext: modelContext, userSettings: userSettings)
    }
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(messages) { message in
                    VStack {
                        if !message.fromUser {
                            HStack(alignment: .center) {
                                if let character = message.character,
                                   let avatar = character.avatar,
                                   let image = UIImage(data: avatar)
                                {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 40, height: 40, alignment: .leading)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40, alignment: .leading)
                                        .clipShape(Circle())
                                }
                                Text(message.character?.name ?? "Unknown Character")
                                    .font(.footnote)
                                    .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
                            }
                        }
                        
                        MessageCell(contentMessage: message.content.swapPlaceholders(userName: chat.userName, charName: message.character?.name, userSettings: userSettings), isCurrentUser: message.fromUser)
                    }
                }
                .padding([.leading, .trailing])
            }
        }
        .navigationTitle(chat.name)
        .navigationBarTitleDisplayMode(.inline)
        .defaultScrollAnchor(.bottom)
        .safeAreaBar(edge: .bottom) {
            GlassEffectContainer(spacing: 10.0) {
                HStack(spacing: 10.0) {
                    TextField("AI Horde", text: $newMessage, axis: .vertical)
                        .keyboardType(.asciiCapable)
                        .lineLimit(5)
                        .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                        .glassEffect(.regular.interactive())
                        .glassEffectUnion(id: "1", namespace: unionNamespace)
                       
                    
                    Menu {
                        Text("Fart")
                    } label: {
                        Image(systemName: newMessage.isEmpty ? "plus" : "arrow.up").padding(5)
                    } primaryAction: {
                        print("Hello")
                    }
                    .buttonStyle(.glass)
                    .glassEffectUnion(id: "2", namespace: unionNamespace)
                    //                .disabled(showPendingMessage)
                    //                .opacity(showPendingMessage ? 0 : 1)
                }.padding([.leading, .trailing, .top])
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Chat.self, configurations: config)
    let modelContext = container.mainContext
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
        alternateGreetings: [],
        tags: [],
        creator: "Brad Root",
        characterVersion: "main",
        chubId: "",
        avatar: UIImage(named: "brad-drawn")!.pngData()!
    )
    container.mainContext.insert(character)
    let chat = Chat(name: "Chat Name", characters: [character])
    container.mainContext.insert(chat)
    for i in 1 ..< 10 {
        let message = ChatMessage(content: "Lorem ipsum dolor sit amet. {{user}}? {{char}}? {{User}}? {{Char}}? consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.", fromUser: i % 2 == 0 ? true : false, chat: chat, character: character)
        container.mainContext.insert(message)
    }
    return NavigationStack {
        NewChatView(for: chat, modelContext: modelContext, userSettings: UserSettings(userCharacter: nil, defaultUserName: "Seymour"))
            .modelContainer(container)
            .navigationTitle("Seymour")
    }
}
