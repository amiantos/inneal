//
//  ChatsView.swift
//  Inneal
//
//  Created by Brad Root on 3/25/24.
//

import SwiftData
import SwiftUI

struct ChatsView: View {
    @Query(sort: [SortDescriptor(\Chat.dateUpdated, order: .reverse)]) var chats: [Chat]
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
            if let selectedChat {
                ChatView(for: selectedChat, modelContext: modelContext).id(selectedChat)
            } else {
                ContentUnavailableView("Use sidebar navigation", systemImage: "sidebar.left")
            }
        }
        .sheet(isPresented: $showingSheet) {
            CreateChatView()
        }
        .sheet(isPresented: $showingHelpSheet) {
            HelpView()
        }
        .sheet(isPresented: $showingCharactersSheet) {
            CharactersView()
        }
        .sheet(isPresented: $showingPersonaSheet) {
            SettingsView()
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
        .onChange(of: chats.count) { oldValue, newValue in
            if (newValue - oldValue) > 0, Preferences.standard.firstTimeSetupCompleted {
                selectedChat = chats.first
            }
        }
    }

    var ChatList: some View {
        List(selection: $selectedChat) {
            ForEach(chats, id: \.self) { chat in
                NavigationLink(value: chat) {
                    HStack {
                        if chat.unwrappedCharacters.count == 1 {
                            if let avatar = chat.unwrappedCharacters.first!.avatar,
                               let image = UIImage(data: avatar)
                            {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60, alignment: .center)
                                    .cornerRadius(30)
                                    .padding(.trailing, 5)
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60, alignment: .center)
                                    .cornerRadius(30)
                                    .padding(.trailing, 5)
                            }
                        } else {
                            Group {
                                ZStack {
                                    LazyHGrid(rows: hGridItems, alignment: .center, spacing: 0) {
                                        ForEach(2 ..< 4, id: \.self) { idx in
                                            if chat.unwrappedCharacters.count > idx {
                                                if let avatar = chat.unwrappedCharacters[idx].avatar,
                                                   let image = UIImage(data: avatar)
                                                {
                                                    Image(uiImage: image)
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 30, height: 30, alignment: .center)
                                                        .cornerRadius(15)
                                                        .offset(x: idx == 3 ? -5 : 5).shadow(radius: 5)
                                                } else {
                                                    Image(systemName: "person.circle.fill")
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 30, height: 30, alignment: .center)
                                                        .cornerRadius(15)
                                                        .offset(x: idx == 3 ? -5 : 5).shadow(radius: 5)
                                                }
                                            }
                                        }
                                    }
                                    LazyVGrid(columns: gridItems, alignment: .center, spacing: 0) {
                                        ForEach(0 ..< 2, id: \.self) { idx in
                                            if let avatar = chat.unwrappedCharacters[idx].avatar,
                                               let image = UIImage(data: avatar)
                                            {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 30, height: 30, alignment: .center)
                                                    .cornerRadius(15)
                                                    .offset(y: idx == 0 ? -5 : 5).shadow(radius: 5)
                                            } else {
                                                Image(systemName: "person.circle.fill")
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 30, height: 30, alignment: .center)
                                                    .cornerRadius(15)
                                                    .offset(y: idx == 0 ? -5 : 5).shadow(radius: 5)
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(minWidth: 60, idealWidth: 60, minHeight: 60, idealHeight: 60)
                            .background(.ultraThinMaterial)
                            .fixedSize()
                            .cornerRadius(30)
                            .padding(.trailing, 5)
                        }
                        VStack {
                            Text(chat.name)
                                .lineLimit(1)
                                .font(.body.bold())
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(((chat.unwrappedMessages.last?.content ?? "") + "\n").swapPlaceholders(userName: chat.userName, charName: chat.characters?.first?.name))
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
        .listStyle(.plain)
        .navigationTitle("\(chats.count) Chats")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    showingPersonaSheet.toggle()
                } label: {
                    Label("You", systemImage: "person")
                }
                Button {
                    showingCharactersSheet.toggle()
                } label: {
                    Label("Characters", systemImage: "person.crop.rectangle.stack")
                }
                Button {
                    showingSheet.toggle()
                } label: {
                    Label("New Chat", systemImage: "square.and.pencil")
                }
            }
            ToolbarItemGroup(placement: .topBarLeading) {
                Button {
                    showingHelpSheet.toggle()
                } label: {
                    Label("Help", systemImage: "questionmark.circle")
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
