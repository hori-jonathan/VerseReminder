//
//  Verse_ReminderApp.swift
//  Verse Reminder
//
//  Created by Jonathan Hori on 7/1/25.
//

import SwiftUI
import FirebaseCore

@main
struct Verse_ReminderApp: App {
    @StateObject private var authViewModel: AuthViewModel

    init() {
        FirebaseApp.configure()

        if CommandLine.arguments.contains("--fastlane-snapshot") ||
            ProcessInfo.processInfo.environment["FASTLANE_SNAPSHOT"] == "YES" {
            UserDefaults.standard.set(true, forKey: "setupComplete")
        }

        _authViewModel = StateObject(wrappedValue: AuthViewModel())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
        }
    }
}
