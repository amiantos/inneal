//
//  MessageHeader.swift
//  Inneal
//
//  Created by Brad Root on 9/15/25.
//

import SwiftData
import SwiftUI

struct MessageHeader: View {
    var message: ChatMessage
    
    var body: some View {
        if !message.fromUser {
            HStack(alignment: .center) {
                if let character = message.character,
                   let avatar = character.avatar,
                   let image = UIImage(data: avatar)
                {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: 40,
                            height: 40,
                            alignment: .leading
                        )
                        .clipShape(Circle())
                } else {
                    Image(
                        systemName: "person.circle.fill"
                    )
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: 40,
                        height: 40,
                        alignment: .leading
                    )
                    .clipShape(Circle())
                }
                Text(
                    message.character?.name
                    ?? "Unknown Character"
                )
                .font(.footnote)
                .frame(
                    maxWidth: .infinity,
                    minHeight: 30,
                    alignment: .leading
                )
            }
        }
    }
}

#Preview {
    MessageHeader(message: ChatMessage(content: "Foo", fromUser: false))
}
