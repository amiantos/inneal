//
//  MessageCell.swift
//  Inneal
//
//  Created by Brad Root on 3/24/24.
//

import SwiftUI

struct MessageCell: View {
    var contentMessage: String
    var isCurrentUser: Bool

    var body: some View {
        Text(LocalizedStringKey(contentMessage))
            .lineLimit(nil)
            .padding(10)
            .foregroundColor(isCurrentUser ? Color.white : Color(UIColor.label))
            .background(isCurrentUser ? Color.accentColor : Color(UIColor.secondarySystemFill))
            .cornerRadius(15)
            .frame(maxWidth: .infinity, alignment: isCurrentUser ? .trailing : .leading)
    }
}

#Preview {
    VStack {
        MessageCell(contentMessage: "*Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.* \"Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\" **Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.** Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.", isCurrentUser: false)
        MessageCell(contentMessage: "*Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.* \"Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\" **Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.** Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.", isCurrentUser: true)
        MessageCell(contentMessage: "Foobar", isCurrentUser: false)
        MessageCell(contentMessage: "Foobar", isCurrentUser: true)
    }
}
