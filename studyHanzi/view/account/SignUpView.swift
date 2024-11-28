//
//  SighUpView.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 17/11/24.
//

import SwiftUI
import Firebase
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift


struct RegisterView: View {
    
    @Binding var isRegistered: Bool
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var successMassage: String?
    
    var body: some View {
        VStack {
            Text("Register")
                .font(.largeTitle)
                .bold()
                .padding()
            TextField("User", text: $username)
                .bold()
                .padding()
                .background(Color.black.opacity(0.2))
                .cornerRadius(8)
                .padding(.horizontal)
            SecureField("Password", text: $password)
                .textContentType(.none)
                .padding()
                .background(Color.black.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            SecureField("ConfirmPassword", text: $confirmPassword)
                .textContentType(.none)
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
                validateRegistration()
            }) {
                Text("Sign up")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            .padding(.top, 40)
            HStack {
                Text("Have an account?")
                    .foregroundColor(.gray)
                Button(action: {
                    isRegistered = true
                }) {
                    Text("Login")
                        .foregroundColor(.blue)
                        .bold()
                }
            }
            .padding(.bottom, 20)
        }
    }
    private func validateRegistration() {
        if !isValidEmail(username) {
            errorMessage = "Invalid email format."
            return
        }
        
        if password.count < 8 {
            errorMessage = "Password must be at least 8 characters."
            return
        }
        
        if password != confirmPassword {
            errorMessage = "Passwords do not match."
            return
        }
        
        registerUser(email: username, password: password)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func registerUser(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.errorMessage = "Registration failed: \(error.localizedDescription)"
                self.successMassage = nil
            } else {
                self.errorMessage = nil
                self.successMassage = "Registration successful!"
                self.isRegistered = true
            }
        }
    }
}
