//
//  NewChatView.swift
//  Inneal
//
//  Created by Brad Root on 8/30/25.
//

import SwiftData
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct NewChatView: View {
    private let chat: Chat
    private var userSettings: UserSettings
    private var viewModel: NewChatView.ViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @Query private var messages: [ChatMessage]
    @State private var newMessage: String = ""
    @State private var showPendingMessage: Bool = false
    @State private var isPendingAlternate: Bool = false
    @State private var statusMessage: String = "Sending message..."
    @State private var opacityLevel = 0.0

    @State private var showingSettingsSheet: Bool = false
    @State private var showingConfirmationDialog: Bool = false
    @State private var showingChatlog: Bool = false
    @State private var batchEditModeEnabled: Bool = false
    @State private var selectedForDeletion: Set<ChatMessage> = .init()
    @State private var selectedCharacter: Character?
    @State private var keyboardShowing: Bool = false
    @FocusState private var isTextFieldFocused: Bool

    @State private var textToEdit: String = ""
    @State private var showTextEditor: Bool = false
    @State private var alternateTextToEdit: String = ""
    @State private var showAlternateTextEditor: Bool = false
    @State private var alternateBeingEdited: ContentAlternate?
    @State private var messageBeingEdited: ChatMessage?

    @State private var showRequestDetails: Bool = false
    @State private var requestDetails: String = ""
    @State private var responseDetails: String = ""

    @State private var showingNewChatSheet: Bool = false

    @State private var currentAlternateIndex: Int = -1

    @Namespace var unionNamespace
    @Namespace var buttonUnionNamespace

    let onNewItem: ([Character]) -> Void

    init(
        for chat: Chat,
        modelContext: ModelContext,
        userSettings: UserSettings,
        onNewItem: @escaping ([Character]) -> Void
    ) {
        Log.debug("Init ChatView for \(chat.name)")
        self.onNewItem = onNewItem
        self.chat = chat
        let id = chat.uuid
        _messages = Query(
            filter: #Predicate { $0.chatUUID == id },
            sort: \.dateCreated
        )
        self.userSettings = userSettings
        viewModel = NewChatView.ViewModel(
            for: chat,
            modelContext: modelContext,
            userSettings: userSettings
        )
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(messages) { message in
                        HStack(alignment: .center, spacing: 10) {
                            if batchEditModeEnabled {
                                Button {
                                    selectMessage(message)
                                } label: {
                                    Image(
                                        systemName:
                                            selectedForDeletion.contains(
                                                message
                                            ) ? "trash.circle" : "circle"
                                    )
                                }
                            }
                            VStack {
                                MessageHeader(message: message)
                                if !isPendingAlternate
                                    || messages.last != message
                                {
                                    MessageCell(
                                        contentMessage: getMessageContent(
                                            for: message
                                        ),
                                        isCurrentUser: message.fromUser
                                    )
                                    .contextMenu {
                                        contextMenu(for: message)
                                    }
                                } else {
                                    MessageCell(
                                        contentMessage: getMessageContent(
                                            for: message
                                        ),
                                        isCurrentUser: message.fromUser
                                    )
                                }
                            }.padding(
                                message.fromUser ? .leading : .trailing,
                                message.fromUser
                                    ? (horizontalSizeClass == .compact
                                        ? 30 : 80)
                                    : (horizontalSizeClass == .compact
                                        ? 30 : 80)
                            )
                        }.id(message)
                    }
                    .padding([.leading, .trailing], (horizontalSizeClass == .regular ? 25 : nil))
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        proxy.scrollTo(messages.last, anchor: .bottom)
                    }
                }
                .onChange(of: messages.count) { oldValue, newValue in
                    if (newValue - oldValue) > 0 {
                        proxy.scrollTo(messages.last, anchor: .bottom)
                    }
                }
            }
            .defaultScrollAnchor(.bottom)
            #if os(iOS)
                .scrollDismissesKeyboard(.interactively)
            #endif
            .navigationTitle(chat.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if batchEditModeEnabled {
                    ToolbarItemGroup(placement: .primaryAction) {
                        batchEditingToolbarItems()
                    }
                } else {
                    if horizontalSizeClass == .regular {
                        #if os(iOS)
                        ToolbarItemGroup(placement: .topBarLeading) {
                            Button {
                                showingNewChatSheet.toggle()
                            } label: {
                                Label(
                                    "New Chat",
                                    systemImage: "square.and.pencil"
                                ).labelStyle(.titleAndIcon)
                            }
                        }
                        #else
                        ToolbarItemGroup(placement: .navigation) {
                            Button {
                                showingNewChatSheet.toggle()
                            } label: {
                                Label(
                                    "New Chat",
                                    systemImage: "square.and.pencil"
                                ).labelStyle(.titleAndIcon)
                            }
                        }
                        #endif
                    }
                    #if os(iOS)
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Menu {
                            ForEach(chat.unwrappedCharacters, id: \.self) {
                                character in
                                Button(
                                    "Edit \(character.name)",
                                    systemImage: "person"
                                ) {
                                    selectedCharacter = character
                                }
                            }
                            if chat.userCharacter != nil {
                                Button(
                                    "Edit \(chat.userCharacter!.name)",
                                    systemImage: "person"
                                ) {
                                    selectedCharacter = chat.userCharacter!
                                }
                            } else if chat.userName == nil,
                                userSettings.userCharacter != nil
                            {
                                Button(
                                    "Edit \(userSettings.userCharacter!.name)",
                                    systemImage: "person"
                                ) {
                                    selectedCharacter = userSettings
                                        .userCharacter!
                                }
                            }
                        } label: {
                            Label("Edit Characters", systemImage: "person.2")
                        }
                        Button("Chat Settings", systemImage: "gearshape") {
                            showingSettingsSheet.toggle()
                        }
                    }
                    #else
                    ToolbarItemGroup(placement: .navigation) {
                        Menu {
                            ForEach(chat.unwrappedCharacters, id: \.self) {
                                character in
                                Button(
                                    "Edit \(character.name)",
                                    systemImage: "person"
                                ) {
                                    selectedCharacter = character
                                }
                            }
                            if chat.userCharacter != nil {
                                Button(
                                    "Edit \(chat.userCharacter!.name)",
                                    systemImage: "person"
                                ) {
                                    selectedCharacter = chat.userCharacter!
                                }
                            } else if chat.userName == nil,
                                userSettings.userCharacter != nil
                            {
                                Button(
                                    "Edit \(userSettings.userCharacter!.name)",
                                    systemImage: "person"
                                ) {
                                    selectedCharacter = userSettings
                                        .userCharacter!
                                }
                            }
                        } label: {
                            Label("Edit Characters", systemImage: "person.2")
                        }
                        Button("Chat Settings", systemImage: "gearshape") {
                            showingSettingsSheet.toggle()
                        }
                    }
                    #endif
                    ToolbarItemGroup(placement: .secondaryAction) {
                        regularTopToolbarItems()
                    }
                }
            }
            .safeAreaBar(edge: .bottom) {
                VStack {
                    if showPendingMessage {
                        Text(statusMessage)
                            .font(.footnote)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .padding(.bottom, 8)
                    }

                    HStack(alignment: .bottom) {
                        Menu {
                            Button {
                                requestMessage(imitation: true)
                            } label: {
                                Label(
                                    "You (Impersonate)",
                                    systemImage: "person.bubble"
                                )
                                Text("Generate a new message for yourself")
                            }
                            ForEach(
                                chat.unwrappedCharacters,
                                id: \.self
                            ) {
                                character in
                                Button {
                                    requestMessage(
                                        fromCharacter: character
                                    )
                                } label: {
                                    Label(
                                        "\(character.name)",
                                        systemImage: "text.bubble"
                                    )
                                    Text("Generate a new message from \(character.name)")
                                }
                            }
                        } label: {
                            Label(
                                "Generate Message",
                                systemImage: "plus.bubble"
                            )
                            .labelStyle(.iconOnly)
                            .frame(width: 30, height: 30)
                        }
                        .buttonStyle(.glass)
                        .disabled(showPendingMessage || isPendingAlternate)
                    

                        TextField(
                            "AI Horde",
                            text: $newMessage,
                            axis: .vertical
                        )
                        .keyboardType(.asciiCapable)
                        .lineLimit(5)
                        .padding(
                            EdgeInsets(
                                top: 11,
                                leading: 10,
                                bottom: 11,
                                trailing: 10
                            )
                        )
                        .frame(minHeight: 30)
                        .onSubmit {
                            if newMessage != "" {
                                requestMessage()
                            }
                        }
                        #if os(iOS)
                        .onReceive(keyboardPublisher) { value in
                            if value {
                                Log.debug("Keyboard Shown")
                                keyboardShowing = true
                            } else {
                                Log.debug("Keyboard Hidden")
                                keyboardShowing = false
                            }
                        }
                        #endif
                        .glassEffect(
                            in: RoundedRectangle(cornerRadius: 20)
                        )

                        if newMessage != "" {
                            Spacer()
                            Button {
                                requestMessage()
                            } label: {
                                Label("Send", systemImage: "arrow.up")
                                    .labelStyle(.iconOnly).frame(
                                        width: 30,
                                        height: 30
                                    )
                            }
                            .buttonStyle(.glassProminent)
                            .disabled(
                                isPendingAlternate || showPendingMessage
                            )
                        }

                        if newMessage == "" {
                            if let lastMessage = messages.last,
                                !lastMessage.fromUser
                            {
                                Spacer()
                                GlassEffectContainer {
                                    HStack {
                                        if !lastMessage
                                            .unwrappedContentAlternates
                                            .isEmpty
                                        {
                                            Button {
                                                if !lastMessage
                                                    .unwrappedContentAlternates
                                                    .isEmpty
                                                {
                                                    if currentAlternateIndex
                                                        == -1
                                                    {
                                                        currentAlternateIndex =
                                                            lastMessage
                                                            .unwrappedContentAlternates
                                                            .count - 1
                                                    } else {
                                                        currentAlternateIndex =
                                                            currentAlternateIndex
                                                            - 1
                                                    }
                                                }
                                            } label: {
                                                Label(
                                                    "Cycle Alternates",
                                                    systemImage:
                                                        "arrow.trianglehead.2.clockwise.rotate.90"
                                                ).labelStyle(.iconOnly).frame(
                                                    width: 30,
                                                    height: 30
                                                )
                                            }
                                            .buttonStyle(.glass)
                                            .glassEffectUnion(
                                                id: "back-retry",
                                                namespace: buttonUnionNamespace
                                            )
                                            .disabled(
                                                isPendingAlternate
                                                    || showPendingMessage
                                            )
                                        }

                                        if !(messages.first == messages.last) {
                                            Button {
                                                getNewAlternateResponseToChat()
                                            } label: {
                                                Label(
                                                    "New Alternate",
                                                    systemImage: "dice"
                                                )
                                                .labelStyle(.iconOnly).frame(
                                                    width: 30,
                                                    height: 30
                                                )
                                            }
                                            .buttonStyle(.glass)
                                            .glassEffectUnion(
                                                id: "back-retry",
                                                namespace: buttonUnionNamespace
                                            )
                                            .disabled(
                                                isPendingAlternate
                                                    || showPendingMessage
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding([.leading, .trailing], (horizontalSizeClass == .regular ? 25 : nil))
                .padding(
                    (keyboardShowing
                        ? [.top, .bottom]
                        : [.top])
                )

            }
            .sheet(isPresented: $showingSettingsSheet) {
                ChatSettingsView(
                    userSettings: userSettings,
                    chat: chat,
                    hordeRequest: viewModel.baseHordeRequest,
                    hordeParams: viewModel.baseHordeParams
                ).interactiveDismissDisabled()
            }
            .sheet(
                isPresented: $showTextEditor,
                content: {
                    TextEditorView(text: $textToEdit)
                }
            )
            .sheet(
                isPresented: $showAlternateTextEditor,
                content: {
                    TextEditorView(text: $alternateTextToEdit)
                }
            )
            .sheet(
                isPresented: $showRequestDetails,
                content: {
                    GenerationDetailsView(
                        responseDetails: $responseDetails,
                        requestDetails: $requestDetails
                    )
                }
            )
            .sheet(
                item: $selectedCharacter,
                content: { character in
                    CharacterView(character: character)
                        .interactiveDismissDisabled()
                }
            )
            .sheet(
                isPresented: $showingChatlog,
                content: {
                    SelectableChatLogView(
                        chat: chat,
                        userSettings: userSettings
                    )
                }
            )
            .sheet(isPresented: $showingNewChatSheet) {
                CreateChatView(onNewItem: onNewItem)
            }
            .onChange(of: isTextFieldFocused) { _, newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation {
                            proxy.scrollTo(messages.last, anchor: .bottom)
                        }
                    }
                }
            }
            .onChange(of: currentAlternateIndex) { _, _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation {
                        proxy.scrollTo(messages.last, anchor: .bottom)
                    }
                }
            }
            .onChange(of: showTextEditor) { _, newValue in
                if !newValue {
                    messageBeingEdited?.content = textToEdit
                }
            }
            .onChange(of: showAlternateTextEditor) { _, newValue in
                if !newValue {
                    alternateBeingEdited?.string = alternateTextToEdit
                }
            }
        }
    }

    fileprivate func getMessageContent(
        for message: ChatMessage
    ) -> String {
        return
            (message == messages.last
            && !message.unwrappedContentAlternates
                .isEmpty
            && currentAlternateIndex >= 0
            && currentAlternateIndex
                < message.unwrappedContentAlternates
                .count
            ? message.unwrappedContentAlternates[
                currentAlternateIndex
            ].string : message.content).swapPlaceholders(
                userName: chat.userName,
                charName: message.character?.name,
                userSettings: userSettings
            )
    }

    @ViewBuilder
    func regularTopToolbarItems() -> some View {
        Button("Chatlog View", systemImage: "list.clipboard") {
            showingChatlog.toggle()
        }
        if !showPendingMessage {
            Button("Batch Delete Mode", systemImage: "trash") {
                batchEditModeEnabled = true
            }
        }
    }

    @ViewBuilder
    func batchEditingToolbarItems() -> some View {
        Button("Delete Selected", systemImage: "trash") {
            batchDeleteMessages()
        }
        Button("Done") {
            selectedForDeletion.removeAll()
            batchEditModeEnabled = false
        }
    }

    @ViewBuilder
    func contextMenu(for message: ChatMessage)
        -> some View
    {
        Button(role: .destructive) {
            if messages.last == message && !message.fromUser
                && currentAlternateIndex != -1
            {
                delete(
                    contentAlternate: message.unwrappedContentAlternates[
                        currentAlternateIndex
                    ]
                )
            } else {
                deleteMessage(message: message)
            }
        } label: {
            Label(
                (currentAlternateIndex != -1
                    ? "Delete Alternate" : "Delete Message"),
                systemImage: "trash"
            )
        }

        Button {
            copyMessageText(message: message)
        } label: {
            Label(
                "Copy Text",
                systemImage: "doc.on.doc"
            )
        }

        Button {
            if messages.last == message && !message.fromUser
                && currentAlternateIndex != -1
            {
                alternateTextToEdit =
                    message.unwrappedContentAlternates[
                        currentAlternateIndex
                    ].string
                alternateBeingEdited =
                    message.unwrappedContentAlternates[
                        currentAlternateIndex
                    ]
                showAlternateTextEditor.toggle()
            } else {
                textToEdit = message.content
                messageBeingEdited = message
                showTextEditor.toggle()
            }
        } label: {
            Label(
                "Edit Text",
                systemImage: "square.and.pencil"
            )
        }

        Group {
            if !message.fromUser,
                message.request != nil
            {
                Button {
                    if messages.last == message && !message.fromUser
                        && currentAlternateIndex != -1
                    {
                        showRequestDetails(
                            message.unwrappedContentAlternates[
                                currentAlternateIndex
                            ].request,
                            message.unwrappedContentAlternates[
                                currentAlternateIndex
                            ].response
                        )
                    } else {
                        showRequestDetails(
                            message.request,
                            message.response
                        )
                    }
                } label: {
                    Label(
                        "Generation Details",
                        systemImage: "info.circle"
                    )
                }
            }
        }
    }

    func copyMessageText(message: ChatMessage) {
        let pasteboard = UIPasteboard.general
        pasteboard.string = message.content.swapPlaceholders(
            userName: chat.userName,
            charName: message.character?.name,
            userSettings: userSettings
        )
    }

    func batchDeleteMessages() {
        for message in selectedForDeletion {
            deleteMessage(message: message)
        }
        selectedForDeletion.removeAll()
        batchEditModeEnabled = false
    }

    func deleteMessage(message: ChatMessage) {
        if !message.unwrappedContentAlternates.isEmpty {
            for alternate in message.unwrappedContentAlternates {
                modelContext.delete(alternate)
            }
        }
        modelContext.delete(message)
    }

    func delete(contentAlternate: ContentAlternate) {
        currentAlternateIndex -= 1
        modelContext.delete(contentAlternate)
    }

    func selectMessage(_ message: ChatMessage) {
        if selectedForDeletion.contains(message) {
            selectedForDeletion.remove(message)
        } else {
            selectedForDeletion.insert(message)
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
        batchEditModeEnabled = false
        if !showPendingMessage, let message = messages.last {
            showPendingMessage.toggle()
            isPendingAlternate.toggle()
            statusMessage = "Requesting a new message..."
            Task {
                let response = await viewModel.getNewResponseToChat(
                    statusMessage: $statusMessage,
                    contentAlternate: true
                )
                let newAlternate = ContentAlternate(
                    string: response.text,
                    request: response.request,
                    response: response.response
                )
                message.contentAlternates?.append(newAlternate)
                chat.dateUpdated = .now
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    currentAlternateIndex =
                        message.unwrappedContentAlternates.count - 1
                    showPendingMessage.toggle()
                    isPendingAlternate.toggle()
                }
            }
        }
    }

    func requestMessage(
        fromCharacter: Character? = nil,
        imitation: Bool = false
    ) {
        batchEditModeEnabled = false
        if currentAlternateIndex >= 0, let currentMessage = messages.last,
            currentMessage.unwrappedContentAlternates.count
                >= currentAlternateIndex + 1, !currentMessage.fromUser
        {
            let alternateContent = currentMessage.unwrappedContentAlternates[
                currentAlternateIndex
            ]
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
            let newUserMessage = ChatMessage(
                content: newMessage,
                fromUser: true,
                chat: chat
            )
            modelContext.insert(newUserMessage)
            chat.dateUpdated = .now
            statusMessage = "Sending message..."
        } else {
            statusMessage = "Requesting a new message..."
        }
        showPendingMessage.toggle()
        newMessage = ""
        currentAlternateIndex = -1
        Task {
            let response = await viewModel.getNewResponseToChat(
                statusMessage: $statusMessage,
                character: fromCharacter,
                imitation: imitation
            )
            if imitation {
                newMessage = response.text
            } else {
                let newResponseMessage = ChatMessage(
                    content: response.text,
                    fromUser: imitation,
                    chat: chat,
                    character: imitation ? nil : response.character,
                    request: response.request,
                    response: response.response
                )
                chat.dateUpdated = Date.now
                modelContext.insert(newResponseMessage)
                chat.dateUpdated = .now
            }
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
    for i in 1..<10 {
        let message = ChatMessage(
            content:
                "Lorem ipsum dolor sit amet. {{user}}? {{char}}? {{User}}? {{Char}}? consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
            fromUser: i % 2 == 0 ? true : false,
            chat: chat,
            character: character
        )
        message.contentAlternates = [
            ContentAlternate(
                string: "Blah",
                message: message,
                request: nil,
                response: nil
            ),
            ContentAlternate(
                string: "Blah 2",
                message: message,
                request: nil,
                response: nil
            ),
            ContentAlternate(
                string: "Blah 3",
                message: message,
                request: nil,
                response: nil
            ),
        ]
        container.mainContext.insert(message)
    }
    return NavigationStack {
        NewChatView(
            for: chat,
            modelContext: modelContext,
            userSettings: UserSettings(
                userCharacter: nil,
                defaultUserName: "Seymour"
            ),
            onNewItem: { blah in
                print(blah)
            }
        )
        .modelContainer(container)
        .navigationTitle("Seymour")
    }
}
