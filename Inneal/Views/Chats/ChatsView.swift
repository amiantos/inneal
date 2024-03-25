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
        .onChange(of: scenePhase, { oldValue, newValue in
            switch newValue {
                case .active:
                if !Preferences.standard.firstTimeSetupCompleted {
                    showIntroductionSheet()
                }
            default:
                break
            }
        })
        .onChange(of: chats.count, { oldValue, newValue in
            if selectedChat == nil && (newValue - oldValue) > 0 && Preferences.standard.firstTimeSetupCompleted {
                selectedChat = chats.first
            }
        })
    }

    var ChatList: some View {
        List(selection: $selectedChat) {
            ForEach(chats, id: \.self) { chat in
                NavigationLink(value: chat) {
                    HStack {
                        if let character = chat.characters?.first,
                           let avatar = character.avatar,
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
                                .frame(width: 60, height: 60, alignment: .center)
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
                    showingCharactersSheet.toggle()
                } label: {
                    Label("Characters", systemImage: "person.2")
                }
            }
            ToolbarItemGroup(placement: .secondaryAction) {
                Button {
                    showingPersonaSheet.toggle()
                } label: {
                    Label("You", systemImage: "person.crop.circle")
                }
                Button {
                    showingHelpSheet.toggle()
                } label: {
                    Label("Help / About", systemImage: "questionmark.circle")
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
