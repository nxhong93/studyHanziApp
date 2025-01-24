//
//  HomeView.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 17/11/24.
//

import SwiftUI

struct HomeView: View {
    @Binding var isLoggedIn: Bool
    @State private var isDarkMode: Bool = true
    @State private var isMenuOpen: Bool = false
    var loggedUsername: String = ""
    var username: String {
        if let atSymbolIndex = loggedUsername.firstIndex(of: "@") {
            return String(loggedUsername[..<atSymbolIndex])
        } else {
            return loggedUsername
        }
    }
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Image(systemName: "person.circle")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(isDarkMode ? .white : .blue)
                        .padding(.leading)
                    
                    Spacer()
                    
                    Text("Hello \(username)")
                        .font(.headline)
                        .foregroundColor(isDarkMode ? .white : .blue)
                    
                    Spacer()
                    
                    SettingsMenu(isDarkMode: $isDarkMode, isLoggedIn: $isLoggedIn)
                }
                .padding(.top)
                
                TabView {
                    NavigationStack {
                        searchView(isDarkMode: $isDarkMode)
                    }
                    .tabItem {
                        Label("Seach", systemImage: "translate")
                    }
                    NavigationStack {
                        learnView(isDarkMode: $isDarkMode)
                    }
                    .tabItem {
                        Label("Learn", systemImage: "book")
                    }
                    NavigationStack {
                        botView()
                    }
                    .tabItem {
                        Label("Bot", systemImage: "message")
                    }
                    NavigationStack {
                        accountView()
                    }
                    .tabItem {
                        Label("Account", systemImage: "person.crop.circle")
                    }
                }
                .accentColor(.blue)
            }
        }
        .background(isDarkMode ? Color.black : Color.white)
    }
}


#Preview {
    HomeView(isLoggedIn: .constant(true))
}
