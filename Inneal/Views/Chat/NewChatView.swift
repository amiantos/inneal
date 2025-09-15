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
    @State var showPendingMessage: Bool = false
    @State var isPendingAlternate: Bool = false
    @State var statusMessage: String = "Sending message..."
    @State private var opacityLevel = 0.0
    
    @State var showingSettingsSheet: Bool = false
    @State private var showingChatlog: Bool = false
    @State private var batchEditModeEnabled: Bool = false
    @State private var selectedCharacter: Character?
    
    @State private var currentAlternateIndex: Int = -1
    
    @Namespace var unionNamespace
    @Namespace var buttonUnionNamespace
    
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
                                        .glassEffect()
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40, alignment: .leading)
                                        .clipShape(Circle())
                                        .glassEffect()
                                }
                                Text(message.character?.name ?? "Unknown Character")
                                    .font(.footnote)
                                    .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
                            }
                        }
                        
                        MessageCell(contentMessage: (message == messages.last && isPendingAlternate ? "..." : (message == messages.last && !message.unwrappedContentAlternates.isEmpty && currentAlternateIndex >= 0 && currentAlternateIndex < message.unwrappedContentAlternates.count ? message.unwrappedContentAlternates[currentAlternateIndex].string : message.content)).swapPlaceholders(userName: chat.userName, charName: message.character?.name, userSettings: userSettings), isCurrentUser: message.fromUser)
                            .padding(message.fromUser ? .leading : .trailing, message.fromUser ? 30 : 0)
                        if !message.fromUser && message == messages.last {
                            GlassEffectContainer {
                                HStack {
                                    if !message.unwrappedContentAlternates.isEmpty {
                                        Button {
                                            if !message.unwrappedContentAlternates.isEmpty {
                                                if currentAlternateIndex == -1 {
                                                    currentAlternateIndex = 0
                                                } else {
                                                    if min(currentAlternateIndex + 1, message.unwrappedContentAlternates.count - 1) == currentAlternateIndex {
                                                        currentAlternateIndex = -1
                                                    } else {
                                                        currentAlternateIndex = min(currentAlternateIndex + 1, message.unwrappedContentAlternates.count - 1)
                                                    }
                                                }
                                            }
                                        } label: {
                                            Label("Undo", systemImage: "arrow.uturn.backward")
                                        }
                                        .buttonStyle(.glass)
                                        .glassEffectUnion(id: "back-retry", namespace: buttonUnionNamespace)
                                        .disabled(isPendingAlternate)
                                    }
                                    
                                    Button {
                                        getNewAlternateResponseToChat()
                                    } label: {
                                        Label("Reroll", systemImage: "dice")
                                    }
                                    .buttonStyle(.glass)
                                    .glassEffectUnion(id: "back-retry", namespace: buttonUnionNamespace)
                                    .disabled(isPendingAlternate)
                                }
                            }
                        }
                    }
                }
                .padding([.leading, .trailing])
            }
        }
        .defaultScrollAnchor(.bottom)
        .navigationTitle(chat.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .secondaryAction) {
                Button("Chat Settings", systemImage: "gearshape") {
                    showingSettingsSheet.toggle()
                }
                Button("Chatlog View", systemImage: "list.clipboard") {
                    showingChatlog.toggle()
                }
                if !showPendingMessage {
                    Button("Batch Delete Mode", systemImage: "trash") {
                        batchEditModeEnabled = true
                    }
                }
                Menu("Characters") {
                    ForEach(chat.unwrappedCharacters, id: \.self) { character in
                        Button("Edit \(character.name)", systemImage: "person") {
                            selectedCharacter = character
                        }
                    }
                    if chat.userCharacter != nil {
                        Button("Edit \(chat.userCharacter!.name)", systemImage: "person") {
                            selectedCharacter = chat.userCharacter!
                        }
                    } else if chat.userName == nil, userSettings.userCharacter != nil {
                        Button("Edit \(userSettings.userCharacter!.name)", systemImage: "person") {
                            selectedCharacter = userSettings.userCharacter!
                        }
                    }
                }
            }
        }
        .safeAreaBar(edge: .bottom) {
            GlassEffectContainer(spacing: 10.0) {
            
                HStack(spacing: 10.0) {
                    TextField("AI Horde", text: $newMessage, axis: .vertical)
                        .keyboardType(.asciiCapable)
                        .lineLimit(5)
                        .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                        .glassEffect(.regular.interactive())
                        .glassEffectUnion(id: "1", namespace: unionNamespace)
                        .onSubmit {
                            requestMessage()
                        }
                    
                    
                    Menu {
                        Button {
                            requestMessage(imitation: true)
                        } label: {
                            Label("Impersonate", systemImage: "person.2.wave.2")
                        }
                        ForEach(chat.unwrappedCharacters, id: \.self) { character in
                            Button {
                                requestMessage(fromCharacter: character)
                            } label: {
                                Label("\(character.name)", systemImage: "person.wave.2")
                            }
                        }
                    } label: {
                        Image(systemName: newMessage.isEmpty ? "plus" : "arrow.up").padding(5)
                    } primaryAction: {
                        requestMessage()
                    }
                    .buttonStyle(.glass)
                    .glassEffectUnion(id: "2", namespace: unionNamespace)
                    //                .disabled(showPendingMessage)
                    //                .opacity(showPendingMessage ? 0 : 1)
                }.padding([.leading, .trailing, .top, .bottom])
            }
        
        }
        .safeAreaBar(edge: .top) {
            if showPendingMessage {
                Text(statusMessage)
                    .padding()
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .glassEffect()
                    .padding([.leading, .trailing])
                    .font(.footnote)
            }
        }
        .sheet(isPresented: $showingSettingsSheet) {
            ChatSettingsView(userSettings: userSettings, chat: chat, hordeRequest: viewModel.baseHordeRequest, hordeParams: viewModel.baseHordeParams).interactiveDismissDisabled()
        }
        .sheet(item: $selectedCharacter, content: { character in
            CharacterView(character: character)
                .interactiveDismissDisabled()
        })
        .sheet(isPresented: $showingChatlog, content: {
            SelectableChatLogView(chat: chat, userSettings: userSettings)
        })
    }
    
    func getNewAlternateResponseToChat() {
//        batchEditModeEnabled = false
        if !showPendingMessage, let message = messages.last {
            showPendingMessage.toggle()
            isPendingAlternate.toggle()
            statusMessage = "Requesting a new message..."
            Task {
                let response = await viewModel.getNewResponseToChat(statusMessage: $statusMessage, contentAlternate: true)
                let newAlternate = ContentAlternate(string: response.text, request: response.request, response: response.response)
                message.contentAlternates?.append(newAlternate)
                chat.dateUpdated = .now
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    currentAlternateIndex = message.unwrappedContentAlternates.count - 1
                    showPendingMessage.toggle()
                    isPendingAlternate.toggle()
                }
            }
        }
    }
    
    func requestMessage(fromCharacter: Character? = nil, imitation: Bool = false) {
//        batchEditModeEnabled = false
        print("Fart?")
        if currentAlternateIndex >= 0, let currentMessage = messages.last, currentMessage.unwrappedContentAlternates.count >= currentAlternateIndex+1, !currentMessage.fromUser {
            let alternateContent = currentMessage.unwrappedContentAlternates[currentAlternateIndex]
            let originalContent = currentMessage.content
            let originalRequest = currentMessage.request
            let originalResponse = currentMessage.response

            currentMessage.content = alternateContent.string
            currentMessage.request = alternateContent.request
            currentMessage.response = alternateContent.response
            alternateContent.string = originalContent
            alternateContent.response = originalResponse
            alternateContent.request = originalRequest
            currentAlternateIndex = -1
        }
        if !newMessage.isEmpty {
            let newUserMessage = ChatMessage(content: newMessage, fromUser: true, chat: chat)
            modelContext.insert(newUserMessage)
            chat.dateUpdated = .now
            statusMessage = "Sending message..."
        } else {
            statusMessage = "Requesting a new message..."
        }
        showPendingMessage.toggle()
        newMessage = ""
        currentAlternateIndex = -1
        try? modelContext.save()
        Task {
            let response = await viewModel.getNewResponseToChat(statusMessage: $statusMessage, character: fromCharacter, imitation: imitation)
            let newResponseMessage = ChatMessage(content: response.text, fromUser: imitation, chat: chat, character: imitation ? nil : response.character, request: response.request, response: response.response)
            chat.dateUpdated = Date.now
            modelContext.insert(newResponseMessage)
            chat.dateUpdated = .now
            try? modelContext.save()
            showPendingMessage.toggle()
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
        message.contentAlternates = [
            ContentAlternate(string: "Blah", message: message, request: nil, response: nil)
        ]
        container.mainContext.insert(message)
    }
    return NavigationStack {
        NewChatView(for: chat, modelContext: modelContext, userSettings: UserSettings(userCharacter: nil, defaultUserName: "Seymour"))
            .modelContainer(container)
            .navigationTitle("Seymour")
    }
}
