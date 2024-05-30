//
//  UserSettingsView.swift
//  Inneal
//
//  Created by Brad Root on 3/25/24.
//

import Foundation
import SwiftData
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct UserSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @Query(sort: [SortDescriptor(\Character.name)]) var characters: [Character]

    @State var userSettings: UserSettings
    @State private var showingSheet = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Your Name"), footer: Text("This is the default name used for you in chats. You can always change it in individual chats if you like, or change it here to affect all existing chats that do not have a name set already.")) {
                    TextField("Wakana Gojou", text: $userSettings.defaultUserName)
                        .disabled(userSettings.userCharacter != nil)
                }
                Section(header: Text("Advanced Options"), footer: Text("You can also pick a character to act as your persona, giving you flexibility to add a description and more to yourself in chats.")) {
                    Picker("Persona", selection: $userSettings.userCharacter) {
                        Text("None").tag(nil as Character?)
                        ForEach(characters) { character in
                            Text(character.name).tag(character as Character?)
                        }
                    }
                    Button("Edit Character") {
                        showingSheet.toggle()
                    }.disabled(userSettings.userCharacter == nil)
                }
            }
            #if os(iOS)
            .scrollDismissesKeyboard(.immediately)
            #endif
            .navigationTitle("About You")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Text("Done") }
                }
            }
            .onChange(of: userSettings.userCharacter) {
                if let uChar = userSettings.userCharacter {
                    userSettings.defaultUserName = uChar.name
                } else {
                    userSettings.defaultUserName = "You"
                }
            }
            .sheet(isPresented: $showingSheet) {
                if userSettings.userCharacter != nil {
                    CharacterView(character: userSettings.userCharacter!)
                        .interactiveDismissDisabled()
                }
            }
        }
    }
}

#Preview {
    UserSettingsView(userSettings: UserSettings(userCharacter: nil, defaultUserName: "You"))
        .modelContainer(PreviewDataController.previewContainer)
}
