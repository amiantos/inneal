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
    @State var text: String

    init(chat: Chat) {
        Log.debug("Init SelectableChatLogView")
        self.chat = chat
        Log.debug("\(self.chat.unwrappedMessages.count)")
        var chatLog = ""
        self.chat.unwrappedMessages.forEach { message in
            Log.debug(message.content)
            let messageContent = "\(message.fromUser ? "{{user}}" : "{{char}}"): \(message.content)"
            chatLog.append("\(messageContent.swapPlaceholders(userName: chat.userName, charName: chat.characters?.first?.name))\n\n")
        }
        self.text = chatLog
    }

    var body: some View {
        NavigationStack {
            TextEditor(text: $text)
                .contentMargins(20.0, for: .scrollContent)
                .keyboardType(.asciiCapable)
                .navigationTitle("Text Chatlog")
                .navigationBarTitleDisplayMode(.inline)
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
