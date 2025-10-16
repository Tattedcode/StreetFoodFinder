//
//  AuthViewModel.swift
//  StreetFoodRater
//
//  Created by GPT on 16/10/2025.
//
//  Kid-Friendly Explanation:
//  This is the "bouncer" at the club door!
//  It checks if you're allowed in (logged in) or if you need to sign up first.
//  It also handles logging out when you want to leave.
//  Think of it like a security guard who remembers who's currently inside!
//

import Foundation
import SwiftUI
import Supabase

/// Manages user authentication state and operations
@MainActor
@Observable
final class AuthViewModel {
    
    /// Current logged-in user (nil if not logged in)
    var currentUser: Supabase.User?
    
    /// Is the user currently logged in?
    var isAuthenticated: Bool {
        currentUser != nil
    }
    
    /// Error message to show if login/signup fails
    var errorMessage: String?
    
    /// Is an auth operation in progress? (show loading spinner)
    var isLoading = false
    
    /// Reference to Supabase manager
    private let supabase = SupabaseManager.shared
    
    init() {
        debugPrint("[AuthViewModel] Initializing...")
        // Check if user is already logged in
        Task {
            await checkSession()
        }
    }
    
    // MARK: - Authentication Actions
    
    /// Check if there's an existing session (already logged in)
    func checkSession() async {
        debugPrint("[AuthViewModel] Checking for existing session...")
        isLoading = true
        
        do {
            let session = try await supabase.client.auth.session
            currentUser = session.user
            debugPrint("[AuthViewModel] ✅ User already logged in: \(session.user.email ?? "Unknown")")
        } catch {
            debugPrint("[AuthViewModel] No existing session - user needs to log in")
            currentUser = nil
        }
        
        isLoading = false
    }
    
    /// Sign up a new user
    func signUp(email: String, password: String) async {
        debugPrint("[AuthViewModel] Attempting sign up for: \(email)")
        isLoading = true
        errorMessage = nil
        
        // Validation
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password"
            isLoading = false
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            isLoading = false
            return
        }
        
        do {
            try await supabase.signUp(email: email, password: password)
            currentUser = supabase.currentUser
            debugPrint("[AuthViewModel] ✅ Sign up successful!")
        } catch {
            debugPrint("[AuthViewModel] ❌ Sign up failed: \(error.localizedDescription)")
            errorMessage = "Sign up failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Log in an existing user
    func signIn(email: String, password: String) async {
        debugPrint("[AuthViewModel] Attempting sign in for: \(email)")
        isLoading = true
        errorMessage = nil
        
        // Validation
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password"
            isLoading = false
            return
        }
        
        do {
            try await supabase.signIn(email: email, password: password)
            currentUser = supabase.currentUser
            debugPrint("[AuthViewModel] ✅ Sign in successful!")
        } catch {
            debugPrint("[AuthViewModel] ❌ Sign in failed: \(error.localizedDescription)")
            errorMessage = "Sign in failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Log out the current user
    func signOut() async {
        debugPrint("[AuthViewModel] Signing out user: \(currentUser?.email ?? "Unknown")")
        isLoading = true
        
        do {
            try await supabase.signOut()
            currentUser = nil
            debugPrint("[AuthViewModel] ✅ Sign out successful")
        } catch {
            debugPrint("[AuthViewModel] ❌ Sign out failed: \(error.localizedDescription)")
            errorMessage = "Sign out failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

