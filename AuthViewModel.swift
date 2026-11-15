//
//  AuthViewModel.swift
//  MyTasks
//

import Foundation
import Combine
import SwiftUI
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var user: User? = nil
    @Published var isSignedIn: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false

    init() {
        self.user = Auth.auth().currentUser
        self.isSignedIn = user != nil
    }

    func signUp(email: String, password: String) {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            self.errorMessage = "Please enter an email address."
            return
        }
        guard !password.isEmpty else {
            self.errorMessage = "Please enter a password."
            return
        }
        guard password.count >= 6 else {
            self.errorMessage = "Password must be at least 6 characters."
            return
        }

        self.errorMessage = nil
        self.isLoading = true

        Auth.auth().createUser(withEmail: trimmedEmail, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                self?.user = result?.user
                self?.isSignedIn = true
            }
        }
    }

    func signIn(email: String, password: String) {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            self.errorMessage = "Please enter an email address."
            return
        }
        guard !password.isEmpty else {
            self.errorMessage = "Please enter your password."
            return
        }

        self.errorMessage = nil
        self.isLoading = true

        Auth.auth().signIn(withEmail: trimmedEmail, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                self?.user = result?.user
                self?.isSignedIn = true
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.isSignedIn = false
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
