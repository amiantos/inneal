//
//  UserSettingsView.swift
//  Inneal
//
//  Created by Brad Root on 3/25/24.
//

import Foundation
import SwiftData
import SwiftUI
import UIKit

struct UserSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @Query(sort: [SortDescriptor(\Character.name)]) var characters: [Character]

    @State var userSettings: UserSettings

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Your Name (in Chats)"), footer: Text("This is the default name used for you in chats. You can always change it in individual chats if you like, or change it here to affect all existing chats that do not have a name set already.")) {
                    TextField("Wakana Gojou", text: $userSettings.defaultUserName)
                }
                Section(header: Text("Advanced Options"), footer: Text("You can also pick a character to act as your persona, giving you flexibility to add a description and more to yourself in chats.")) {
                    Picker("Persona", selection: $userSettings.userCharacter) {
                        Text("None").tag(nil as Character?)
                        ForEach(characters) { character in
                            Text(character.name).tag(character as Character?)
                        }
                    }
                    Button("Edit Character") {
                        Log.debug("Foo")
                    }.disabled(userSettings.userCharacter == nil)
                }
            }
            #if os(iOS)
            .scrollDismissesKeyboard(.immediately)
            #endif
            .navigationTitle("You")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Text("Done") }
                }
            }
        }
    }
}

#Preview {
    UserSettingsView(userSettings: UserSettings(userCharacter: nil, defaultUserName: "You"))
        .modelContainer(PreviewDataController.previewContainer)
}
