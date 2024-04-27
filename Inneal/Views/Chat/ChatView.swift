//
//  ChatView.swift
//  Inneal
//
//  Created by Brad Root on 3/24/24.
//

import SwiftData
import SwiftUI

@MainActor
struct ChatView: View {
    let chat: Chat
    var viewModel: ChatView.ViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State var newMessage: String = ""
    @Environment(\.modelContext) var modelContext
    @Query var messages: [ChatMessage]
    @State var showPendingMessage: Bool = false
    @State var textToEdit: String = ""
    @State var showTextEditor: Bool = false
    @State var alternateTextToEdit: String = ""
    @State var showAlternateTextEditor: Bool = false
    @State var alternateBeingEdited: ContentAlternate?
    @State var messageBeingEdited: ChatMessage?
    @State var showingSettingsSheet: Bool = false
    @State private var scrollID: String?
    @State var textSize: CGSize = CGSize(width: 10, height: 10)
    @State var showingCharacterSheet: Bool = false
    @State var statusMessage: String = "Sending message..."
    @State private var opacityLevel = 0.0
    @State private var requestDetails: String = ""
    @State private var responseDetails: String = ""
    @State private var showRequestDetails: Bool = false

    init(for chat: Chat, modelContext: ModelContext) {
        Log.debug("Init ChatView for \(chat.name)")
        self.chat = chat
        let id = chat.uuid
        _messages = Query(filter: #Predicate { $0.chatUUID == id }, sort: \.dateCreated)
        viewModel = ChatView.ViewModel(for: chat, modelContext: modelContext)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ZStack {
                VStack {
                    // MARK: - Chat Content Area
                    GeometryReader { geometryProxy in
                        ScrollView(.vertical) {
                            LazyVStack {
                                ForEach(messages) { message in
                                    HStack(alignment: .bottom, spacing: 10) {
                                        VStack {
                                            HStack(alignment: .center) {
                                                if !message.fromUser {
                                                    if !message.fromUser {
                                                        if let character = chat.characters?.first,
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
                                                    }
                                                    Text(message.character?.name ?? "Unknown Character")
                                                        .font(.footnote)
                                                        .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
                                                }
                                            }
                                            if !message.fromUser && message == messages.last {
                                                ScrollView(.horizontal) {
                                                    LazyHStack(alignment: .top, spacing: 0) {
                                                        HStack {
                                                            MessageCell(contentMessage: message.content.swapPlaceholders(userName: chat.userName, charName: message.character?.name), isCurrentUser: message.fromUser)
                                                                .fixedSize(horizontal: false, vertical: true)
                                                                .readIntrinsicContentSize(to: $textSize)
                                                                .contextMenu {
                                                                    Button(role: .destructive) {
                                                                        deleteMessage(message: message)
                                                                    } label: {
                                                                        Label("Delete Message", systemImage: "trash")
                                                                    }

                                                                    Button {
                                                                        copyMessageText(message: message)
                                                                    } label: {
                                                                        Label("Copy Text", systemImage: "doc.on.doc")
                                                                    }

                                                                    Button {
                                                                        textToEdit = message.content
                                                                        messageBeingEdited = message
                                                                        showTextEditor.toggle()
                                                                    } label: {
                                                                        Label("Edit", systemImage: "square.and.pencil")
                                                                    }

                                                                    Group {
                                                                        if !message.fromUser, message.request != nil {
                                                                            Button {
                                                                                showRequestDetails(message.request, message.response)
                                                                            } label: {
                                                                                Label("Generation Details", systemImage: "info.circle")
                                                                            }
                                                                        }
                                                                    }
                                                                }

                                                            if !message.unwrappedContentAlternates.isEmpty || messages.count > 1 {
                                                                Image(systemName: message.unwrappedContentAlternates.isEmpty ? "arrow.clockwise" : "chevron.right")
                                                            }

                                                        }
                                                        .id("primary")
                                                        .containerRelativeFrame(.horizontal)


                                                        ForEach(message.unwrappedContentAlternates) { alternate in
                                                            HStack(alignment: .top) {
                                                                HStack {
                                                                    Image(systemName: "chevron.left")
                                                                    MessageCell(contentMessage: alternate.string.swapPlaceholders(userName: chat.userName, charName: message.character?.name), isCurrentUser: message.fromUser)
                                                                        .fixedSize(horizontal: false, vertical: true)
                                                                        .readIntrinsicContentSize(to: $textSize)
                                                                        .contextMenu {
                                                                            Button(role: .destructive) {
                                                                                delete(contentAlternate: alternate)
                                                                            } label: {
                                                                                Label("Delete Alternate", systemImage: "trash")
                                                                            }

                                                                            Button {
                                                                                copyText(contentAlternate: alternate)
                                                                            } label: {
                                                                                Label("Copy Text", systemImage: "doc.on.doc")
                                                                            }

                                                                            Button {
                                                                                alternateTextToEdit = alternate.string
                                                                                alternateBeingEdited = alternate
                                                                                showAlternateTextEditor.toggle()
                                                                            } label: {
                                                                                Label("Edit", systemImage: "square.and.pencil")
                                                                            }

                                                                            Group {
                                                                                if alternate.request != nil {
                                                                                    Button {
                                                                                        showRequestDetails(alternate.request, alternate.response)
                                                                                    } label: {
                                                                                        Label("Generation Details", systemImage: "info.circle")
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    if alternate != message.unwrappedContentAlternates.last || messages.count > 1 {
                                                                        Image(systemName: alternate != message.unwrappedContentAlternates.last ? "chevron.right" : "arrow.clockwise")
                                                                    }
                                                                }
                                                            }.id(alternate.uuid.uuidString).containerRelativeFrame(.horizontal)
                                                        }

                                                        if messages.count > 1 {
                                                            HStack(alignment: .center) {
                                                                ProgressView().padding()
                                                            }
                                                            .id("newAlternate")
                                                            .padding(10)
                                                            .containerRelativeFrame([.horizontal, .vertical])
                                                            .fixedSize(horizontal: false, vertical: true)
                                                            .foregroundColor(Color(UIColor.label))
                                                            .background(Color(UIColor.tertiarySystemFill))
                                                            .cornerRadius(15)
                                                        }

                                                    }.scrollTargetLayout().frame(height: textSize.height)
                                                }
                                                .scrollTargetBehavior(.viewAligned)
                                                .scrollPosition(id: $scrollID)
                                                .scrollDisabled(showPendingMessage)
                                                .scrollIndicators(.hidden)
                                                .frame(height: textSize.height)
                                                .onChange(of: textSize) { oldValue, newValue in
                                                    if message.unwrappedContentAlternates.isEmpty {
                                                        Log.debug("Alternates empty, setting \(newValue.height) over \(oldValue.height)")
                                                        textSize = newValue
                                                    } else if oldValue.height > newValue.height {
                                                        Log.debug("Old value is greater, setting \(oldValue.height) over \(newValue.height)")
                                                        textSize = oldValue
                                                    } else {
                                                        Log.debug("Setting \(newValue.height) over \(oldValue.height)")
                                                        textSize = newValue
                                                    }
                                                }
                                            } else {
                                                MessageCell(contentMessage: message.content.swapPlaceholders(userName: chat.userName, charName: message.character?.name), isCurrentUser: message.fromUser)
                                                    .contextMenu {
                                                        Button(role: .destructive) {
                                                            deleteMessage(message: message)
                                                        } label: {
                                                            Label("Delete Message", systemImage: "trash")
                                                        }

                                                        Button {
                                                            copyMessageText(message: message)
                                                        } label: {
                                                            Label("Copy Text", systemImage: "doc.on.doc")
                                                        }

                                                        Button {
                                                            textToEdit = message.content
                                                            messageBeingEdited = message
                                                            showTextEditor.toggle()
                                                        } label: {
                                                            Label("Edit", systemImage: "square.and.pencil")
                                                        }

                                                        Group {
                                                            if !message.fromUser, message.request != nil {
                                                                Button {
                                                                    showRequestDetails(message.request, message.response)
                                                                } label: {
                                                                    Label("Generation Details", systemImage: "info.circle")
                                                                }
                                                            }
                                                        }

                                                    }
                                            }
                                        }
                                    }
                                    .id(message)
                                    .frame(maxWidth: .infinity, alignment: message.fromUser ? .trailing : .leading)
                                    .padding([.leading, .trailing], 10)
                                    .padding(message.fromUser ? .leading : .trailing, message.fromUser ? 30 : 0)
                                    .padding(.bottom, 10)
                                }
                            }
                            .onChange(of: messages.count, { oldValue, newValue in
                                if (newValue - oldValue) > 0 {
                                    proxy.scrollTo(messages.last, anchor: .bottom)
                                }
                            })
                        }
                        .safeAreaInset(edge: .bottom, alignment: .center, spacing: 0) {
                            // MARK: - Chat Textfield
                            HStack(alignment: .bottom) {
                                TextField("AI Horde", text: $newMessage, axis: .vertical)
                                    .keyboardType(.asciiCapable)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(5)
                                    .onSubmit {
                                        sendMessage()
                                    }
                                    .onReceive(keyboardPublisher) { value in
                                        if value {
                                            Log.debug("Keyboard Shown")
                                            withAnimation {
                                                proxy.scrollTo(messages.last, anchor: .bottom)
                                            }
                                        } else {
                                            Log.debug("Keyboard Hidden")
                                        }
                                      }
                                ZStack {
                                    ProgressView()
                                        .opacity(showPendingMessage ? 1 : 0)
                                    Button(action: sendMessage) {
                                        Image(systemName: "arrow.up")
                                    }
                                    .clipShape(Circle())
                                    .buttonStyle(BorderedProminentButtonStyle())
                                    .disabled(showPendingMessage)
                                    .opacity(showPendingMessage ? 0 : 1)
                                }
                                .padding(.leading, 2)
                            }
                            .padding([.top, .leading, .trailing, .bottom])
                            .background(.ultraThickMaterial)

                            // MARK: End of Chat Textfield
                        }
                        .defaultScrollAnchor(.bottom)
#if os(iOS)
                        .scrollDismissesKeyboard(.interactively)
#endif
                    }

                }
                // MARK: - Status Overlay
                VStack(alignment: .center) {
                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .allowsHitTesting(false)
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThickMaterial)
                        .overlay(Divider()
                            .frame(maxWidth: .infinity, maxHeight: 1)
                            .background(Color(.opaqueSeparator)), alignment: .bottom
                        )
                        .opacity(opacityLevel)
                        .animation(.easeInOut(duration: 0.5), value: opacityLevel)
                    Spacer()
                }.allowsHitTesting(false)

            }
        }
        .navigationTitle(chat.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .secondaryAction) {
                Button("Chat Settings", systemImage: "gearshape") {
                    showingSettingsSheet.toggle()
                }
                Button("Edit Character", systemImage: "person") {
                    showingCharacterSheet.toggle()
                }
            }
        }
        .sheet(isPresented: $showingSettingsSheet) {
            ChatSettingsView(chat: chat, hordeRequest: viewModel.baseHordeRequest, hordeParams: viewModel.baseHordeParams)
        }
        .sheet(isPresented: $showingCharacterSheet) {
            if let character = chat.characters?.first {
                CharacterView(character: character)
            }
        }
        .sheet(isPresented: $showTextEditor, content: {
            TextEditorView(text: $textToEdit)
        })
        .sheet(isPresented: $showAlternateTextEditor, content: {
            TextEditorView(text: $alternateTextToEdit)
        })
        .sheet(isPresented: $showRequestDetails, content: {
            GenerationDetailsView(responseDetails: $responseDetails, requestDetails: $requestDetails)
        })
        .onChange(of: showingSettingsSheet) { oldValue, newValue in
            if !newValue {
                viewModel.saveSettingsToChat()
            }
        }
        .onChange(of: scrollID) { oldValue, newValue in
            if newValue == "newAlternate" {
                getNewAlternateResponseToChat()
            }
        }
        .onChange(of: showTextEditor) { _, newValue in
            if !newValue {
                messageBeingEdited?.content = textToEdit
                try? modelContext.save()
            }
        }
        .onChange(of: showAlternateTextEditor) { _, newValue in
            if !newValue {
                alternateBeingEdited?.string = alternateTextToEdit
                try? modelContext.save()
            }
        }
        .onChange(of: showPendingMessage) { _, newValue in
            if newValue {
                withAnimation {
                    opacityLevel = 1.0
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        if opacityLevel == 1.0 {
                            opacityLevel = 0.0
                        }
                    }
                }
            }
        }
    }

    func showRequestDetails(_ request: String?, _ response: String?) {
        if let request, let response {
            let jsonRequestData = Data(request.utf8)
            requestDetails = jsonRequestData.printJson() ?? ""
            let jsonResponseData = Data(response.utf8)
            responseDetails = jsonResponseData.printJson() ?? ""
            showRequestDetails.toggle()
        }
    }

    func getNewAlternateResponseToChat() {
        if !showPendingMessage, let message = messages.last {
            showPendingMessage.toggle()
            statusMessage = "Requesting a new message..."
            Task {
                let response = await viewModel.getNewResponseToChat(statusMessage: $statusMessage, ignoreLastMessage: true)
                let newAlternate = ContentAlternate(string: response.text, message: message, request: response.request, response: response.response)
                chat.dateUpdated = .now
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    scrollID = newAlternate.uuid.uuidString
                    showPendingMessage.toggle()
                }
            }
        }
    }

    func sendMessage() {
        if let id = scrollID, id != "primary", let currentMessage = messages.last, !currentMessage.fromUser, let alternateContent = currentMessage.unwrappedContentAlternates.filter({ $0.uuid.uuidString == id }).first {
            let originalContent = currentMessage.content
            let originalRequest = currentMessage.request
            let originalResponse = currentMessage.response

            currentMessage.content = alternateContent.string
            currentMessage.request = alternateContent.request
            currentMessage.response = alternateContent.response
            alternateContent.string = originalContent
            alternateContent.response = originalResponse
            alternateContent.request = originalRequest
            scrollID = "primary"
        }
        if !newMessage.isEmpty {
            let newUserMessage = ChatMessage(content: newMessage, fromUser: true, chat: chat)
            modelContext.insert(newUserMessage)
            chat.dateUpdated = .now
            try? modelContext.save()
        }
        statusMessage = "Sending message..."
        showPendingMessage.toggle()
        newMessage = ""
        Task {
            let response = await viewModel.getNewResponseToChat(statusMessage: $statusMessage)
            let newResponseMessage = ChatMessage(content: response.text, fromUser: false, chat: chat, character: chat.characters?.first!, request: response.request, response: response.response)
            chat.dateUpdated = Date.now
            modelContext.insert(newResponseMessage)
            chat.dateUpdated = .now
            try? modelContext.save()
            showPendingMessage.toggle()
        }
    }

    func deleteMessage(message: ChatMessage) {
        if !message.unwrappedContentAlternates.isEmpty {
            message.unwrappedContentAlternates.forEach { alternate in
                modelContext.delete(alternate)
            }
        }
        modelContext.delete(message)
    }

    func delete(contentAlternate: ContentAlternate) {
        modelContext.delete(contentAlternate)
        scrollID = "primary"
    }

    func copyText(contentAlternate: ContentAlternate) {
        let pasteboard = UIPasteboard.general
        pasteboard.string = contentAlternate.string.swapPlaceholders(userName: chat.userName, charName: contentAlternate.message?.character?.name)
    }

    func copyMessageText(message: ChatMessage) {
        let pasteboard = UIPasteboard.general
        pasteboard.string = message.content.swapPlaceholders(userName: chat.userName, charName: message.character?.name)
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
        ChatView(for: chat, modelContext: modelContext)
            .modelContainer(container)
            .navigationTitle("Edit Character")
    }
}
