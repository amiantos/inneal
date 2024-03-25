//
//  TextEditorView.swift
//  Inneal
//
//  Created by Brad Root on 4/21/24.
//

import SwiftUI

struct TextEditorView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var text: String

    var body: some View {
        NavigationStack {
            TextEditor(text: $text)
                .keyboardType(.asciiCapable)
                .padding()
                .navigationTitle("Edit Message")
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
