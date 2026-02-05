//
//  AuthView.swift
//  nailApp


import SwiftUI

struct AuthView: View {
    @StateObject private var authService = AuthService.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var isLoginMode = true
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image("nailart")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 150, height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .pink.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    Text(isLoginMode ? "Welcome Back" : "Create Account")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(isLoginMode ? "Sign in to continue" : "Sign up to get started")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
                
                VStack(spacing: 20) {
                    if !isLoginMode {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                                TextField("Enter your name", text: $displayName)
                                    .textContentType(.name)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.gray)
                            TextField("Enter your email", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(.gray)
                            SecureField("Enter your password", text: $password)
                                .textContentType(isLoginMode ? .password : .newPassword)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    if !isLoginMode {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.gray)
                                SecureField("Confirm your password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
                
                Button(action: handleAuth) {
                    HStack {
                        Spacer()
                        if authService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(isLoginMode ? "Sign In" : "Sign Up")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.pink, .purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .disabled(!isFormValid || authService.isLoading)
                .opacity(isFormValid ? 1.0 : 0.6)
                .padding(.horizontal)
                .contentShape(Rectangle())
                
                Button(action: { isLoginMode.toggle() }) {
                    Text(isLoginMode ? "Don't have an account? Sign Up" : "Already have an account? Sign In")
                        .font(.subheadline)
                        .foregroundColor(.pink)
                }
                
                Button(action: { dismiss() }) {
                    Text("Continue as Guest")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 8)
                
                Spacer()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onChange(of: authService.currentUser?.isGuest) { oldValue, newValue in
           
            if oldValue != false && newValue == false {
                dismiss()
            }
        }
        .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
          
            if isAuthenticated, let user = authService.currentUser, !user.isGuest {
                dismiss()
            }
        }
    }
    
    private var isFormValid: Bool {
        if email.isEmpty || password.isEmpty {
            return false
        }
        
        if !email.isValidEmail {
            return false
        }
        
        if !isLoginMode {
            if displayName.isEmpty {
                return false
            }
            if confirmPassword.isEmpty {
                return false
            }
            if password != confirmPassword {
                return false
            }
            if password.count < 6 {
                return false
            }
        }
        
        return true
    }
    
    private func handleAuth() {
        Task {
            do {
                if isLoginMode {
                    try await authService.signIn(email: email, password: password)
                } else {
                    try await authService.signUp(email: email, password: password, displayName: displayName)
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

#Preview {
    AuthView()
}
