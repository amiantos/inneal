//
//  ChatsView.swift
//  Inneal
//
//  Created by Brad Root on 3/25/24.
//

import SwiftData
import SwiftUI

struct ChatsView: View {
    @Query(sort: [SortDescriptor(\Chat.dateUpdated, order: .reverse)])
    var chats: [Chat]
    @Environment(\.modelContext) var modelContext
    @State private var showingSheet = false
    @State private var showingNameAlert = false
    @State private var showingDefaultContentAlert = false
    @State private var name = ""
    @State private var showingHelpSheet = false
    @Environment(\.scenePhase) var scenePhase
    @State private var showingIntroSheet = false
    @State private var showingCharactersSheet = false
    @State private var showingPersonaSheet = false
    @State private var selectedChat: Chat?
    @State private var userSettings: UserSettings?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let gridItems = [
        GridItem(.fixed(30), spacing: -5, alignment: .leading),
        GridItem(.fixed(30), spacing: -5, alignment: .leading),
    ]

    let hGridItems = [
        GridItem(.fixed(30), spacing: -5, alignment: .leading),
        GridItem(.fixed(30), spacing: -5, alignment: .leading),
    ]

    var body: some View {
        NavigationSplitView {
            ChatList
        } detail: {
            if let selectedChat, let userSettings {
                NewChatView(
                    for: selectedChat,
                    modelContext: modelContext,
                    userSettings: userSettings,
                    onNewItem: { selectedCharacters in
                        addNewChat(selectedCharacters: selectedCharacters)
                    }
                ).id(selectedChat)
            } else {
                ContentUnavailableView(
                    "Use sidebar navigation",
                    systemImage: "sidebar.left"
                ).navigationTitle("Inneal").navigationBarTitleDisplayMode(
                    .inline
                ).toolbar {
                    if horizontalSizeClass == .regular {
                        ToolbarItemGroup(placement: .topBarLeading) {
                            Button {
                                showingSheet.toggle()
                            } label: {
                                Label(
                                    "New Chat",
                                    systemImage: "square.and.pencil"
                                ).labelStyle(.titleAndIcon)
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingSheet) {
            CreateChatView(onNewItem: { selectedCharacters in
                addNewChat(selectedCharacters: selectedCharacters)
            })
        }
        .sheet(isPresented: $showingHelpSheet) {
            HelpView()
        }
        .sheet(isPresented: $showingCharactersSheet) {
            CharactersView(onNewItem: { selectedCharacters in
                addNewChat(selectedCharacters: selectedCharacters)
            })
        }
        .sheet(isPresented: $showingPersonaSheet) {
            if userSettings != nil {
                UserSettingsView(userSettings: userSettings!)
            }
        }
        .fullScreenCover(isPresented: $showingIntroSheet) {
            IntroductionView()
        }
        .onChange(of: scenePhase) { _, newValue in
            switch newValue {
            case .active:
                if !Preferences.standard.firstTimeSetupCompleted {
                    showIntroductionSheet()
                }
            default:
                break
            }
        }
        .onAppear {
            do {
                let descriptor = FetchDescriptor<UserSettings>()
                let configurations = try modelContext.fetch(descriptor)
                if !configurations.isEmpty, let settings = configurations.first
                {
                    userSettings = settings
                    Log.debug(
                        "Loaded user settings from DB, name: \(settings.defaultUserName), character: \(settings.userCharacter?.name ?? "nil")"
                    )
                } else {
                    let settings = UserSettings(
                        userCharacter: nil,
                        defaultUserName: Preferences.standard.defaultName
                    )
                    modelContext.insert(settings)
                    userSettings = settings
                }
            } catch {
                Log.error("Errorl loading or creating user settings")
            }
        }
    }

    private func addNewChat(selectedCharacters: [Character]) {
        if !selectedCharacters.isEmpty {
            guard
                let characterNames = selectedCharacters.compactMap({ $0.name })
                    as? [String]
            else { return }
            let chatName = characterNames.joined(separator: " & ")
            Log.debug("Chat Name \(chatName)")

            let chat = Chat(
                name: chatName,
                characters: Array(selectedCharacters)
            )
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
                    let contentAlternate = ContentAlternate(
                        string: greeting,
                        message: message
                    )
                    modelContext.insert(contentAlternate)
                }
            }

            selectedChat = chat
        }
    }

    var ChatList: some View {
        List(selection: $selectedChat) {
            ForEach(chats, id: \.self) { chat in
                NavigationLink(value: chat) {
                    HStack {
                        if chat.unwrappedCharacters.count == 1 {
                            if let avatar = chat.unwrappedCharacters.first!
                                .avatar,
                                let image = UIImage(data: avatar)
                            {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(
                                        width: 60,
                                        height: 60,
                                        alignment: .center
                                    )
                                    .cornerRadius(30)
                                    .padding(.trailing, 5)
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(
                                        width: 60,
                                        height: 60,
                                        alignment: .center
                                    )
                                    .cornerRadius(30)
                                    .padding(.trailing, 5)
                            }
                        } else {
                            Group {
                                ZStack {
                                    LazyHGrid(
                                        rows: hGridItems,
                                        alignment: .center,
                                        spacing: 0
                                    ) {
                                        ForEach(2..<4, id: \.self) { idx in
                                            if chat.unwrappedCharacters.count
                                                > idx
                                            {
                                                if let avatar =
                                                    chat.unwrappedCharacters[
                                                        idx
                                                    ].avatar,
                                                    let image = UIImage(
                                                        data: avatar
                                                    )
                                                {
                                                    Image(uiImage: image)
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(
                                                            width: 30,
                                                            height: 30,
                                                            alignment: .center
                                                        )
                                                        .cornerRadius(15)
                                                        .offset(
                                                            x: idx == 3 ? -5 : 5
                                                        ).shadow(radius: 5)
                                                } else {
                                                    Image(
                                                        systemName:
                                                            "person.circle.fill"
                                                    )
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(
                                                        width: 30,
                                                        height: 30,
                                                        alignment: .center
                                                    )
                                                    .cornerRadius(15)
                                                    .offset(
                                                        x: idx == 3 ? -5 : 5
                                                    ).shadow(radius: 5)
                                                }
                                            }
                                        }
                                    }
                                    LazyVGrid(
                                        columns: gridItems,
                                        alignment: .center,
                                        spacing: 0
                                    ) {
                                        ForEach(0..<2, id: \.self) { idx in
                                            if idx
                                                < chat.unwrappedCharacters.count,
                                                let avatar =
                                                    chat.unwrappedCharacters[
                                                        idx
                                                    ].avatar,
                                                let image = UIImage(
                                                    data: avatar
                                                )
                                            {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(
                                                        width: 30,
                                                        height: 30,
                                                        alignment: .center
                                                    )
                                                    .cornerRadius(15)
                                                    .offset(
                                                        y: idx == 0 ? -5 : 5
                                                    ).shadow(radius: 5)
                                            } else if idx
                                                < chat.unwrappedCharacters.count
                                            {
                                                Image(
                                                    systemName:
                                                        "person.circle.fill"
                                                )
                                                .resizable()
                                                .scaledToFill()
                                                .frame(
                                                    width: 30,
                                                    height: 30,
                                                    alignment: .center
                                                )
                                                .cornerRadius(15)
                                                .offset(y: idx == 0 ? -5 : 5)
                                                .shadow(radius: 5)
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(
                                minWidth: 60,
                                idealWidth: 60,
                                minHeight: 60,
                                idealHeight: 60
                            )
                            .fixedSize()
                            .cornerRadius(30)
                            .padding(.trailing, 5)
                        }
                        VStack {
                            Text(chat.name)
                                .lineLimit(1)
                                .font(.body.bold())
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(
                                ((chat.unwrappedMessages.last?.content ?? "")
                                    + "\n").swapPlaceholders(
                                        userName: chat.userName,
                                        charName: chat.unwrappedMessages.last?
                                            .character?.name,
                                        userSettings: userSettings
                                            ?? UserSettings(
                                                userCharacter: nil,
                                                defaultUserName: "You"
                                            )
                                    )
                            )
                            .lineLimit(2)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .onDelete(perform: deleteChats)
            .listSectionSeparator(.hidden, edges: .top)
        }
        .navigationTitle("Inneal")
        .navigationSubtitle("\(chats.count) Chats")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.inset)
        .toolbar(removing: .sidebarToggle)
        .toolbar {
            ToolbarItemGroup(placement: .secondaryAction) {
                Button {
                    showingHelpSheet.toggle()
                } label: {
                    Label("About Inneal", systemImage: "questionmark.circle")
                }
            }
            
            ToolbarItemGroup(placement: .automatic) {
                Button {
                    showingPersonaSheet.toggle()
                } label: {
                    Label("Your Persona", systemImage: "person")
                }
                Button {
                    showingCharactersSheet.toggle()
                } label: {
                    Label(
                        "Characters",
                        systemImage: "person.crop.rectangle.stack"
                    )
                }
            }
            if horizontalSizeClass == .compact {
                ToolbarSpacer(.flexible, placement: .bottomBar)
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        showingSheet.toggle()
                    } label: {
                        Label("New Chat", systemImage: "square.and.pencil")
                            .labelStyle(.iconOnly).frame(width: 30, height: 30)
                    }.buttonStyle(.glassProminent)
                }
            }
        }
    }

    func deleteChats(at offsets: IndexSet) {
        for offset in offsets {
            let chat = chats[offset]
            modelContext.delete(chat)
        }
    }

    func showIntroductionSheet() {
        showingIntroSheet = true
    }
}

#Preview {
    ChatsView()
        .modelContainer(PreviewDataController.previewContainer)
}
