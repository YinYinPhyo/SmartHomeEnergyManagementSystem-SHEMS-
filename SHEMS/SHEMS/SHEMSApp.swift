//
//  SHEMSApp.swift
//  SHEMS
//
//  Created by QSCare on 2/22/25.
//

//
//  SHEMSApp.swift
//  SHEMS
//

import SwiftUI
import SwiftData
import FirebaseCore
import UserNotifications


class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()

        // Set delegate and request permission
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted.")
            } else {
                print("❌ Notification permission denied.")
            }
        }

        // (Optional) Register for remote notifications
        // application.registerForRemoteNotifications()

        return true
    }

    // Show notifications even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

@main
struct SHEMSApp: App {
    @StateObject private var appState = AppState()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Theme setting
        @AppStorage("appTheme") private var selectedTheme: String = "system"

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(resolveColorScheme(from: selectedTheme))
        }
    }
    // Helper to map string to ColorScheme
       func resolveColorScheme(from theme: String) -> ColorScheme? {
           switch theme {
           case "light":
               return .light
           case "dark":
               return .dark
           default:
               return nil // system default
           }
       }
}

