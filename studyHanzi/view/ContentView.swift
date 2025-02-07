//
//  ContentView.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 16/11/24.
//

import SwiftUI
import Firebase
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift



struct ContentView: View {
    
    @State private var isRegistered = true
    @State private var isLoggedIn = false
    @State private var loggedUserName: String = ""
    
    
    var body: some View {
        if isLoggedIn {
            HomeView(isLoggedIn: $isLoggedIn, loggedUsername: $loggedUserName)
            .onChange(of: isLoggedIn) { oldValue, newValue in
                if !newValue {
                    loggedUserName = ""
                }
            }
        } else {
            NavigationStack {
                ZStack {
                    Image("background")
                        .resizable()
                        .ignoresSafeArea()
                    VStack {
                        Spacer()
                            
                        if isRegistered {
                            LoginView(isLoggedIn: $isLoggedIn, isRegistered: $isRegistered, loggedUserName: $loggedUserName)
                                .onAppear {
                                    checkLoginStatus()
                                }
                        } else {
                            RegisterView(isRegistered: $isRegistered)
                        }
                    }
                }
            }
        }
    }
    
    private func checkLoginStatus() {
        if let currentUser = Auth.auth().currentUser {
            loggedUserName = currentUser.email ?? "Unknown"
            isLoggedIn = true
        }
    }
}


#Preview {
    ContentView()
}
