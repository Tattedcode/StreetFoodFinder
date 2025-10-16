//
//  LoginView.swift
//  StreetFoodRater
//
//  Created by GPT on 16/10/2025.
//
//  Kid-Friendly Explanation:
//  This is the "front door" of the app!
//  Like entering your username and password to get into your email,
//  this screen lets you type your email and password to access the app.
//  If you don't have an account yet, there's a button to create one!
//

import SwiftUI

struct LoginView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.purple.opacity(0.6), Color.orange.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // App Logo / Title
                    VStack(spacing: 12) {
                        Image(systemName: "map.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(Color.white)
                        
                        Text("Street Food Finder")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(Color.white)
                        
                        Text("Discover & Rate Food Carts")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.white.opacity(0.9))
                    }
                    .padding(.top, 60)
                    
                    // Login Form
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
                            
                            SecureField("••••••••", text: $password)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
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
                        
                        // Login Button
                        Button {
                            debugPrint("[LoginView] Login button tapped")
                            Task {
                                await authViewModel.signIn(email: email, password: password)
                            }
                        } label: {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Log In")
                                    .font(.headline)
                                    .foregroundStyle(Color.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                        .disabled(authViewModel.isLoading)
                        
                        // Sign Up Link
                        HStack {
                            Text("Don't have an account?")
                                .foregroundStyle(Color.white.opacity(0.9))
                            
                            Button {
                                debugPrint("[LoginView] Sign up button tapped")
                                showSignUp = true
                            } label: {
                                Text("Sign Up")
                                    .font(.headline)
                                    .foregroundStyle(Color.white)
                                    .underline()
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSignUp) {
                SignUpView()
                    .environment(authViewModel)
            }
        }
    }
}

#Preview {
    LoginView()
        .environment(AuthViewModel())
}

