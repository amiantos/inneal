//
//  InnealApp.swift
//  Inneal
//
//  Created by Brad Root on 3/24/24.
//

import SwiftData
import SwiftUI

@main
struct InnealApp: App {
    init() {
        Log.logLevel = .debug
        Log.useEmoji = true

        Log.info("App initialized...")
    }
    
    var body: some Scene {
        WindowGroup {
            ChatsView()
        }
        .modelContainer(for: [Chat.self, APIConfiguration.self])
    }
}

enum MyError: Error {
    case runtimeError(String)
}
