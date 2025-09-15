//
//  SwiftQuizApp.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

import SwiftUI
import UserNotifications

#if os(iOS)
    import UIKit

    class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
        func application(_ application: UIApplication,
                         didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
            UNUserNotificationCenter.current().delegate = self
            return true
        }

        func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                    withCompletionHandler completionHandler: @escaping () -> Void) {
            Task { @MainActor in
                let handled = NotificationService.shared.handleNotificationResponse(response)
                if handled {
                    NotificationCenter.default.post(name: .openQuizFromNotification, object: nil)
                }
            }
            completionHandler()
        }

        func userNotificationCenter(_ center: UNUserNotificationCenter,
                                    willPresent notification: UNNotification,
                                    withCompletionHandler completionHandler:
                                    @escaping (UNNotificationPresentationOptions)
                                        -> Void) {
            completionHandler([.alert, .sound, .badge])
        }
    }

#elseif os(macOS)
    import AppKit

    class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
        func applicationDidFinishLaunching(_ notification: Notification) {
            UNUserNotificationCenter.current().delegate = self
        }

        func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                    withCompletionHandler completionHandler: @escaping () -> Void) {
            Task { @MainActor in
                let handled = NotificationService.shared.handleNotificationResponse(response)
                if handled {
                    NotificationCenter.default.post(name: .openQuizFromNotification, object: nil)
                }
            }
            completionHandler()
        }

        func userNotificationCenter(_ center: UNUserNotificationCenter,
                                    willPresent notification: UNNotification,
                                    withCompletionHandler completionHandler:
                                    @escaping (UNNotificationPresentationOptions)
                                        -> Void) {
            completionHandler([.alert, .sound, .badge])
        }
    }
#endif

@main
struct SwiftQuizApp: App {
    #if os(iOS)
        @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #elseif os(macOS)
        @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    let persistenceController = PersistenceController.shared
    @StateObject private var notificationService = NotificationService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, self.persistenceController.container.viewContext)
                .environmentObject(self.notificationService)
                .task {
                    await self.notificationService.checkAuthorizationStatus()
                }
            #if os(iOS)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    Task {
                        await self.notificationService.checkAuthorizationStatus()
                    }
                }
            #elseif os(macOS)
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                    Task {
                        await self.notificationService.checkAuthorizationStatus()
                    }
                }
            #endif
        }
        #if os(macOS)
        .windowResizability(.contentSize)
        .defaultSize(width: 600, height: 700)
        #endif
    }
}

extension Notification.Name {
    static let openQuizFromNotification = Notification.Name("openQuizFromNotification")
}
