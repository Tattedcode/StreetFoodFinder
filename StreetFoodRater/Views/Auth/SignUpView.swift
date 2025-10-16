//
//  SignUpView.swift
//  StreetFoodRater
//
//  Created by GPT on 16/10/2025.
//
//  Kid-Friendly Explanation:
//  This is like filling out a form to get your library card for the first time!
//  You type your email and create a password, and the app creates an account for you.
//  Then you can log in anytime with that same email and password!
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var authViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.orange.opacity(0.6), Color.purple.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill.badge.plus")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.white)
                        
                        Text("Create Account")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color.white)
                        
                        Text("Join the food community!")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.white.opacity(0.9))
                    }
                    .padding(.top, 60)
                    
                    // Sign Up Form
                    VStack(spacing: 20) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.headline)
                                .foregroundStyle(Color.white)
                            
                            TextField("your@email.com", text: $email)
                                .textFieldStyle(.plain)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.headline)
                                .foregroundStyle(Color.white)
                            
                            SecureField("At least 6 characters", text: $password)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.headline)
                                .foregroundStyle(Color.white)
                            
                            SecureField("Re-enter password", text: $confirmPassword)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Password Mismatch Warning
                        if !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword {
                            Text("Passwords don't match")
                                .font(.caption)
                                .foregroundStyle(Color.red)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.9))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        // Error Message
                        if let error = authViewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(Color.red)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.9))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        // Sign Up Button
                        Button {
                            debugPrint("[SignUpView] Sign up button tapped")
                            Task {
                                await authViewModel.signUp(email: email, password: password)
                                // If successful, dismiss the sheet
                                if authViewModel.isAuthenticated {
                                    dismiss()
                                }
                            }
                        } label: {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Create Account")
                                    .font(.headline)
                                    .foregroundStyle(Color.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(password == confirmPassword && !password.isEmpty ? Color.orange : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                        .disabled(authViewModel.isLoading || password != confirmPassword || password.isEmpty)
                        
                        // Cancel Button
                        Button {
                            debugPrint("[SignUpView] Cancel tapped")
                            dismiss()
                        } label: {
                            Text("Already have an account? Log In")
                                .foregroundStyle(Color.white.opacity(0.9))
                                .underline()
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    SignUpView()
        .environment(AuthViewModel())
}

