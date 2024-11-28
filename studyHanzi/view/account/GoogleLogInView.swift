//
//  AuthenticationViewModel.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 17/11/24.
//

import SwiftUI
import Firebase
import FirebaseAuth
import GoogleSignIn



class GoogleSignInManager: ObservableObject {
    @Published var isSignedIn = false

    func signInWithGoogle(presentingViewController: UIViewController, completion: @escaping () -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("Firebase ClientID not found")
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] result, error in
            if let error = error {
                print("Google Sign-In failed: \(error.localizedDescription)")
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                print("Google Sign-In returned no user or ID token.")
                return
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase Sign-In failed: \(error.localizedDescription)")
                } else {
                    print("Firebase Sign-In successful!")
                    self?.isSignedIn = true
                    completion()
                }
            }
        }
    }
}

