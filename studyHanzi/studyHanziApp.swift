//
//  studyHanziApp.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 16/11/24.
//
import UIKit
import SwiftUI
import FirebaseCore
import GoogleSignIn


class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
    }
}

@main
struct studyHanziApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }
    }
}
