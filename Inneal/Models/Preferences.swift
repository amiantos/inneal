//
//  Preferences.swift
//  Inneal
//
//  Created by Brad Root on 4/5/24.
//

import Foundation

enum Preferences {
    fileprivate enum Key {
        static let defaultName = "defaultName"
        static let firstTimeSetupCompleted = "firstTimeSetupCompleted"
    }

    static var standard: UserDefaults {
        let database = UserDefaults.standard
        database.register(defaults: [
            Key.defaultName: "You",
            Key.firstTimeSetupCompleted: false,

        ])

        return database
    }
}

extension UserDefaults {
    var defaultName: String {
        string(forKey: Preferences.Key.defaultName) ?? "You"
    }

    func set(defaultName: String) {
        set(defaultName, forKey: Preferences.Key.defaultName)
    }

    var firstTimeSetupCompleted: Bool {
        bool(forKey: Preferences.Key.firstTimeSetupCompleted)
    }

    func set(firstTimeSetupCompleted: Bool) {
        set(firstTimeSetupCompleted, forKey: Preferences.Key.firstTimeSetupCompleted)
    }
}

private extension UserDefaults {
    func set(_ object: Any?, for key: String) {
        set(object, forKey: key)
        synchronize()
    }
}
