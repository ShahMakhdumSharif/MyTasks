//
//  MyTasksApp.swift
//  MyTasks
//

import SwiftUI
import Firebase

@main
struct MyTasksApp: App {
    
    @StateObject private var viewModel = AuthViewModel()

    init() {
        FirebaseApp.configure()
        print("Configured Firebase!!!")
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if viewModel.isSignedIn {
                    ContentView()
                        .environmentObject(viewModel)
                } else {
                    AuthView(viewModel: viewModel)
                }
            }
        }
    }
}

// MARK: - Fluent Authentication View
struct AuthView: View {
    @ObservedObject var viewModel: AuthViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isPasswordVisible = false
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email
        case password
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 24)
                
                // Header / Branding
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 80, height: 80)
                            .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
                        
                        Image(systemName: "note.text")
                            .font(.system(size: 38, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Text(isSignUp ? "Create Account" : "Welcome Back")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(isSignUp ? "Sign up to start saving and syncing your notes." : "Sign in to access your saved notes.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                // Mode Switcher
                Picker("Mode", selection: $isSignUp) {
                    Text("Sign In").tag(false)
                    Text("Sign Up").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)
                .onChange(of: isSignUp) { _ in
                    viewModel.errorMessage = nil
                }
                
                // Form Card
                VStack(spacing: 16) {
                    // Email Field
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        TextField("Email address", text: $email)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .password
                            }
                        
                        if !email.isEmpty {
                            Button(action: { email = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(focusedField == .email ? Color.blue : Color.clear, lineWidth: 1.5)
                    )
                    
                    // Password Field
                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        if isPasswordVisible {
                            TextField("Password (min. 6 characters)", text: $password)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .focused($focusedField, equals: .password)
                                .submitLabel(.go)
                                .onSubmit {
                                    handleAction()
                                }
                        } else {
                            SecureField("Password (min. 6 characters)", text: $password)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .textContentType(isSignUp ? .newPassword : .password)
                                .focused($focusedField, equals: .password)
                                .submitLabel(.go)
                                .onSubmit {
                                    handleAction()
                                }
                        }
                        
                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(focusedField == .password ? Color.blue : Color.clear, lineWidth: 1.5)
                    )
                }
                .padding(.horizontal, 24)
                
                // Error Alert Banner
                if let errorMessage = viewModel.errorMessage {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 16))
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button(action: { viewModel.errorMessage = nil }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.red.opacity(0.8))
                        }
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // Primary Action Button
                Button(action: handleAction) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                                .padding(.trailing, 6)
                        }
                        Text(isSignUp ? "Sign Up" : "Sign In")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(isFormFilled ? Color.blue : Color.blue.opacity(0.6))
                    .cornerRadius(12)
                    .shadow(color: isFormFilled ? .blue.opacity(0.3) : .clear, radius: 8, y: 4)
                }
                .disabled(viewModel.isLoading)
                .padding(.horizontal, 24)
                
                // Mode Toggle Footer
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSignUp.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                            .foregroundColor(.secondary)
                        Text(isSignUp ? "Sign In" : "Sign Up")
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }
                .padding(.top, 4)
                
                Spacer(minLength: 24)
            }
            .padding(.vertical)
        }
        .scrollDismissesKeyboard(.interactively)
    }
    
    private var isFormFilled: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.isEmpty
    }
    
    private func handleAction() {
        focusedField = nil
        if isSignUp {
            viewModel.signUp(email: email, password: password)
        } else {
            viewModel.signIn(email: email, password: password)
        }
    }
}
