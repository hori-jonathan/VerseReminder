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
    @UIApplicationDelegateAdaptor(FirebaseAppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
        }
    }
}
