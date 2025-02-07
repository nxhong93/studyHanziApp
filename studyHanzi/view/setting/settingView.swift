//
//  settingView.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 18/11/24.
//

import SwiftUI
import FirebaseAuth



struct SettingsMenu: View {
    @Binding var isDarkMode: Bool
    @Binding var isLoggedIn: Bool
    var onLogout: () -> Void
    @State private var showingLogoutAlert: Bool = false

    var body: some View {
        Menu {
            Toggle(isOn: $isDarkMode) {
                Label("Dark Mode", systemImage: "moon.fill")
            }

            Button(role: .destructive, action: {
                showingLogoutAlert = true
            }) {
                Label("Logout", systemImage: "arrow.backward.circle.fill")
            }
        } label: {
            Image(systemName: "gearshape.fill")
                .resizable()
                .frame(width: 30, height: 30)
                .foregroundColor(isDarkMode ? .white : .blue)
                .padding(.trailing)
        }
        .alert("Confirm Logout", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                logout()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .environment(\.colorScheme, isDarkMode ? .dark : .light)
    }

    private func logout() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            isLoggedIn = false
            onLogout()
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError.localizedDescription)")
        }
    }
}
