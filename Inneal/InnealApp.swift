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

    var sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: Chat.self, APIConfiguration.self)
        } catch {
            fatalError()
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView(container: sharedModelContainer)
        }
    }
}

enum MyError: Error {
    case runtimeError(String)
}
