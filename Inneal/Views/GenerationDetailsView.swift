//
//  GenerationDetailsView.swift
//  Inneal
//
//  Created by Brad Root on 4/24/24.
//

import SwiftUI

struct GenerationDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var responseDetails: String
    @Binding var requestDetails: String

    let myMonoFont: Font = .system(size: 12).monospaced()

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Response")) {
                    Text(responseDetails)
                        .font(myMonoFont)
                        .textSelection(.enabled)
                }
                Section(header: Text("Request")) {
                    Text(requestDetails)
                        .font(myMonoFont)
                        .textSelection(.enabled)
                }
            }
            .navigationTitle("Generation Details")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
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

// #Preview {
//    TextViewerView(text: Binding<String>("Foo"))
// }
