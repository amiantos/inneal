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
        for message in self.chat.unwrappedMessages {
            Log.debug(message.content)
            let messageContent = "\(message.fromUser ? "{{user}}" : "{{char}}"): \(message.content)"
            var userName = "You"
            if let uChar = chat.userCharacter {
                userName = uChar.name
            } else if let uName = chat.userName {
                userName = uName
            }
            chatLog.append("\(messageContent.swapPlaceholders(userName: userName, charName: message.character?.name))\n\n")
        }
        text = chatLog
    }

    var body: some View {
        NavigationStack {
            TextEditor(text: $text)
                .ignoresSafeArea(.container)
                .contentMargins(.horizontal, 15.0, for: .scrollContent)
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
