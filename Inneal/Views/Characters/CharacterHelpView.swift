//
//  CharacterHelpView.swift
//  Inneal
//
//  Created by Brad Root on 4/22/24.
//

import SwiftUI

struct CharacterHelpView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack {
                    HelpTextView {
                        Text("How do I write good characters?").font(.title3).bold().padding(.bottom, 6)
                        Text("Writing good character cards is more art than science, because of how much variation there are in LLM behaviors. The creator of this app isn't even totally sure what makes the difference between good and bad character cards, just that he knows one when he chats with one.\n\nWith that in mind, some good advice would be to find an existing character card you like, and look at how it was built and written. Compare that to character cards you *don't* like, and in the end you may have a good idea on how to write your own cards.\n\nAs generative AI technology improves, all character cards will improve naturally. Experiment, try something that feels right to you, and see what the results are. We're all beginners here, there are no wrong answers as long as *you* are having fun.")
                    }
                }
            }
            .toolbar{
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Text("Done") }
                }
            }
            .navigationTitle("Character Editor FAQ")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    CharacterHelpView()
}
