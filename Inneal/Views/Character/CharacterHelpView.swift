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
                        Text("Advice for how to write good character cards varies, and the creator of this app is slowly developing his own theories.\n\nFocus on keeping your character's description in third person. (e.g. \"Bradley is a white male. Bradley likes Nine Inch Nails.\") It really should just be a complete outline of their interests, opinions, and a physical description. This is the most important thing, and if you use this character as a persona, keeping it very generic and focused on the individual character will make it adaptable to more scenarios and group chats. Do not put scenario related content in the description.\n\nUse the first message, and the first message alternates, to set up scenarios for the chat itself. Do not write descriptions or dialog for the player character in the character's messages, a chat message originating from a bot should only write for itself, no one else. It can be very annoying when a bot writes for you when you didn't want it to, and a lot of the fault for this lies in how the first message was written, so be thoughtful with your writing.\n\nPick a writing style and stick to it. I think, most obviously, a [third person omniscient narration style](https://www.masterclass.com/articles/third-person-omniscient-narration-guide) would give you and the bot most flexibility in how to describe inner thoughts and actions. But, [third person limited](https://www.masterclass.com/articles/tips-for-writing-third-person-limited-point-of-view) could also bear fruit, where the subject of the story may be the character and your presence in it is merely as dialog, fodder for the character to bounce off of. I think first person narration styles can be interesting but I think LLMs still have a hard time keeping track of who 'I', 'you', 'me' is precisely. Third person is probably a safer bet.\n\nAll that said, I am no expert, and there are other sources that could be fun to read, including but not limited to:\n\n• https://rentry.co/alichat\n• https://rentry.co/kingbri-chara-guide\n• https://rentry.co/plists_alichat_avakson\n• https://rentry.org/chai-pygmalion-tips\n• https://rentry.org/pygtips#character-creation-tips\n\nBut most of all, experiment, and have fun!")
                    }
                }
            }
            .toolbar {
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
