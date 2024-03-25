//
//  HelpView.swift
//  Inneal
//
//  Created by Brad Root on 4/15/24.
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack {
                    HelpTextView {
                        Text("What is Inneal?").font(.title3).bold().padding(.bottom, 6)
                        Text("*Inneal* is a chat-oriented client for the *AI Horde*, similar to SillyTavern, Agnaistic, and others.\n\nInneal allows you to create *Character Cards* that describe the personality and traits of characters, and then chat with those characters, using open source LLM models provided by enthusiastic volunteers, other people just like you.")
                    }
                    HelpTextView {
                        Text("What is the AI Horde?").font(.title3).bold().padding(.bottom, 6)
                        Text("The AI Horde is a crowdsourced cluster of generative AI related tools, including but not limited to text generation and image generation models. For Inneal, we use the LLMs provided by volunteers to generate responses to your chats.\n\n**Use of the AI Horde is fully anonymous by default, and free to use.**\n\nTo prevent abuse of this generosity, the AI Horde uses a kudos system to prioritize requests. The more kudos you have, the faster your requests are processed. Kudos deplete as you make requests, and can be replenished by volunteering workers to the horde. This is much easier than you may think, visit https://aihorde.net for more information.")
                    }
                    HelpTextView {
                        Text("Who built this?").font(.title3).bold().padding(.bottom, 6)
                        Text("Inneal was built by Brad Root, also known as Amiantos. He's also built a client for the image generation side of the AI Horde, an app called Aislingeach.\n\nhttps://github.com/amiantos/aislingeach")
                    }
                    HelpTextView {
                        Text("Need more help?").font(.title3).bold().padding(.bottom, 6)
                        Text("It's easy to get in touch with me, if you have more questions.\n\nYou can email me directly at bradroot@me.com, don't be shy!\n\nOn Discord, my username is **amiantos**.\n\nYou can send me a friend request, but also you find me in the AI Horde Discord in the #inneal channel. Join here: https://discord.gg/QHxkdJtXar\n\nIt's fun to meet likeminded people, so you should consider joining!")
                    }
                }



            }
            .toolbar{
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Text("Done") }
                }
            }
            .navigationTitle("Inneal Help")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    NavigationStack {
        HelpView()

    }
}

struct HelpTextView<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading) {
            content()
        }
        .padding()
        .background(Color(UIColor.secondarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 25.0))
        .padding([.leading, .trailing, .bottom])
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
