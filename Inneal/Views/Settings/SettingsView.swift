//
//  SettingsView.swift
//  Inneal
//
//  Created by Brad Root on 3/25/24.
//

import Foundation
import SwiftUI
import UIKit

struct SettingsView: View {
    @State var defaultName: String = Preferences.standard.defaultName
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Your Name (in Chats)"), footer: Text("This is the default name used for you in chats. You can always change it in individual chats if you like, or change it here to affect all existing chats that do not have a name set already.")) {
                    TextField("Wakana Gojou", text: $defaultName)
                        .onChange(of: defaultName) { _, _ in
                            Preferences.standard.set(defaultName: defaultName)
                        }
                }
            }
            #if os(iOS)
            .scrollDismissesKeyboard(.immediately)
            #endif
            .navigationTitle("You")
            .toolbar{
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Text("Done") }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(PreviewDataController.previewContainer)
}
