//
//  LogInView.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 17/11/24.
//

import SwiftUI
import Firebase
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift


struct LoginView: View {
    
    @Binding var isLoggedIn: Bool
    @Binding var isRegistered: Bool
    @Binding var loggedUserName: String
    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @ObservedObject private var googleSignInManager = GoogleSignInManager()
    
    var body: some View {
        VStack {
            Text("Login")
                .font(.largeTitle)
                .bold()
                .padding(.bottom, 20)
            TextField("User", text: $username)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .padding(.horizontal)
            
            SecureField("Password", text: $password)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .padding(.horizontal)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            Button(action: {
                validateLogin()
            }) {
                Text("Login")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            Button(action: {
                if let rootViewController = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first?.windows.first?.rootViewController {
                    googleSignInManager.signInWithGoogle(presentingViewController: rootViewController) {
                        self.isLoggedIn = true
                    }
                }
            }) {
                Text("Sign in with Google")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            .padding(.top, 20)
            HStack {
                Text("Don't have an account?")
                    .foregroundColor(.gray)
                Button(action: {
                    isRegistered = false
                }) {
                    Text("Sign Up")
                        .foregroundColor(.blue)
                        .bold()
                }
            }
            .padding(.bottom, 20)
        }
    }
    private func validateLogin() {
        if username.isEmpty || password.isEmpty {
            errorMessage = "Username and password cannot be empty."
            return
        }
        let email = username.contains("@") ? username : "\(username)@gmail.com"
        
        
        Auth.auth().signIn(withEmail: email, password: password) {authResult, error in
            if let error = error {
                self.errorMessage = "Login failed: \(error.localizedDescription)"
                return
            }
            
            loggedUserName = username
            errorMessage = nil
            isLoggedIn = true
            print("Login successful!")
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}
