//
//  SelectableChatLogView.swift
//  Inneal
//
//  Created by Brad Root on 5/3/24.
//

import SwiftUI

struct SelectableChatLogView: View {
    @Environment(\.dismiss) var dismiss
    let chat: Chat
    let userSettings: UserSettings
    @State var text: String

    init(chat: Chat, userSettings: UserSettings) {
        Log.debug("Init SelectableChatLogView")
        self.chat = chat
        self.userSettings = userSettings
        Log.debug("\(self.chat.unwrappedMessages.count)")
        var chatLog = ""
        for message in self.chat.unwrappedMessages {
            Log.debug(message.content)
            let messageContent = "\(message.fromUser ? "{{user}}" : "{{char}}"): \(message.content)"
            chatLog.append("\(messageContent.swapPlaceholders(userName: chat.userName, charName: message.character?.name, userSettings: userSettings))\n\n")
        }
        text = chatLog
    }

    var body: some View {
        NavigationStack {
            TextEditor(text: $text)
                .ignoresSafeArea(.container)
                .contentMargins(.horizontal, 15.0, for: .scrollContent)
            #if !os(macOS)
                .keyboardType(.asciiCapable)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .navigationTitle("Text Chatlog")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}
