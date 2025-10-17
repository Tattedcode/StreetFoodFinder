//
//  ProfileView.swift
//  StreetFoodRater
//
//  Created by GPT on 16/10/2025.
//
//  Kid-Friendly Explanation:
//  This is YOUR personal page!
//  It shows your stats (how many ratings you've made),
//  your email, and has a button to log out.
//  Think of it like your profile page on Instagram!
//

import SwiftUI
import Supabase
import PhotosUI

struct ProfileView: View {
    let model: RatingsViewModel
    
    @Environment(AuthViewModel.self) private var authViewModel
    
    // Profile picture state
    @State private var selectedProfilePhoto: PhotosPickerItem?
    @State private var profileImageData: Data?
    @State private var isUploadingPhoto = false
    
    // Delete account state
    @State private var showDeleteConfirmation = false
    @State private var showFinalWarning = false
    @State private var isDeletingAccount = false
    @State private var deleteError: String?
    
    // Nuclear reset state (for testing only!)
    @State private var showNuclearWarning1 = false
    @State private var showNuclearWarning2 = false
    @State private var showNuclearWarning3 = false
    @State private var isNukingDatabase = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Profile Header
                    profileHeader
                    
                    // Stats Cards
                    statsSection
                    
                    // Your Ratings List
                    yourRatingsSection
                    
                    // Logout Button
                    logoutButton
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color.purple.opacity(0.1), Color.orange.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Profile")
            .onAppear {
                Task {
                    await loadExistingProfilePhoto()
                }
            }
        }
    }
    
    // MARK: - Components
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Profile Picture with Photo Picker
            PhotosPicker(selection: $selectedProfilePhoto, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    // Profile Image or Default Icon
                    if let imageData = profileImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(LinearGradient(colors: [Color.purple, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 4)
                            )
                    } else {
                        Circle()
                            .fill(LinearGradient(colors: [Color.purple, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.white)
                            )
                    }
                    
                    // Camera badge
                    Circle()
                        .fill(Color.white)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.purple)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .shadow(color: Color.purple.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            
            if isUploadingPhoto {
                ProgressView()
                    .tint(.purple)
                Text("Uploading...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // User Email
            if let email = authViewModel.currentUser?.email {
                Text(email)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            // Member Since
            Text("Food Explorer 🌟")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .onChange(of: selectedProfilePhoto) { _, newValue in
            Task {
                await loadProfilePhoto(from: newValue)
            }
        }
    }
    
    private var statsSection: some View {
        HStack(spacing: 16) {
            // Total Ratings
            StatCard(
                icon: "star.fill",
                value: "\(yourRatingsCount)",
                label: "Ratings",
                color: .orange
            )
            
            // Locations Visited
            StatCard(
                icon: "mappin.circle.fill",
                value: "\(uniqueLocationsCount)",
                label: "Places",
                color: .purple
            )
            
            // Average Rating Given
            StatCard(
                icon: "heart.fill",
                value: String(format: "%.1f", averageRatingGiven),
                label: "Avg Rating",
                color: .pink
            )
        }
    }
    
    private var yourRatingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Recent Ratings")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            if yourRatings.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "star.slash")
                        .font(.system(size: 50))
                        .foregroundStyle(.gray.opacity(0.5))
                    Text("No ratings yet")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Tap the + button to rate your first food cart!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(yourRatings.prefix(5)) { rating in
                    RatingRowCard(rating: rating)
                }
            }
        }
    }
    
    private var logoutButton: some View {
        VStack(spacing: 16) {
            // Logout Button
            Button {
                debugPrint("[ProfileView] Logout button tapped")
                Task {
                    await authViewModel.signOut()
                }
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Log Out")
                }
                .font(.headline)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Delete Account Button
            Button {
                debugPrint("[ProfileView] Delete account button tapped")
                showDeleteConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Delete Account")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // ⚠️ NUCLEAR RESET BUTTON (TESTING ONLY!)
            VStack(spacing: 8) {
                Text("⚠️ TESTING ONLY")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fontWeight(.bold)
                
            Button {
                debugPrint("[ProfileView] ☢️ NUCLEAR RESET tapped")
                showNuclearWarning1 = true
            } label: {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("DELETE ALL DATA + Sign Out")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.red, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow, lineWidth: 2)
                )
            }
            .disabled(isNukingDatabase)
            
            if isNukingDatabase {
                ProgressView("Deleting everything and signing out...")
                    .font(.caption)
            }
            }
            .padding(.top, 20)
            
            .alert("Delete Account?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    showFinalWarning = true
                }
            } message: {
                Text("Are you sure? This will delete all your ratings and reviews.")
            }
            .alert("⚠️ Final Warning", isPresented: $showFinalWarning) {
                Button("Cancel", role: .cancel) {}
                Button("Yes, Delete Everything", role: .destructive) {
                    Task {
                        await deleteAccount()
                    }
                }
            } message: {
                Text("This cannot be undone! Your account, ratings, and photos will be permanently deleted.")
            }
            
            // NUCLEAR RESET WARNINGS (3 confirmations!)
            .alert("☢️ NUCLEAR OPTION", isPresented: $showNuclearWarning1) {
                Button("Cancel", role: .cancel) {}
                Button("Continue", role: .destructive) {
                    showNuclearWarning2 = true
                }
            } message: {
                Text("This will delete EVERYONE's data from the database and SIGN YOU OUT! This includes all users, all ratings, all locations, and all photos. Are you ABSOLUTELY sure?")
            }
            .alert("⚠️ SECOND WARNING", isPresented: $showNuclearWarning2) {
                Button("Cancel", role: .cancel) {}
                Button("Yes, I'm Sure", role: .destructive) {
                    showNuclearWarning3 = true
                }
            } message: {
                Text("This will wipe the entire database clean and sign you out. All testing data will be gone. You'll need to create a new account. This action is IRREVERSIBLE.")
            }
            .alert("🚨 FINAL CONFIRMATION", isPresented: $showNuclearWarning3) {
                Button("Cancel", role: .cancel) {}
                Button("NUKE EVERYTHING", role: .destructive) {
                    Task {
                        await nuclearReset()
                    }
                }
            } message: {
                Text("Last chance! Press 'NUKE EVERYTHING' to delete all data from all users and sign out. You'll return to the login screen.")
            }
            
            if isDeletingAccount {
                HStack {
                    ProgressView()
                    Text("Deleting account...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var yourRatings: [FoodRating] {
        guard let userId = authViewModel.currentUser?.id else { return [] }
        // Filter ratings to only show the current user's ratings
        let userRatings = model.ratings.filter { $0.userId == userId }
        debugPrint("[ProfileView] 📊 Filtering ratings for user \(userId):")
        debugPrint("  Total ratings in app: \(model.ratings.count)")
        debugPrint("  User's ratings: \(userRatings.count)")
        return userRatings
    }
    
    private var yourRatingsCount: Int {
        yourRatings.count
    }
    
    private var uniqueLocationsCount: Int {
        // Count unique locations by NAME + coordinates
        // This ensures "Mama's Pad Thai" and "Som Tam Stand" are counted as separate places
        // even if they're right next to each other
        let uniquePlaces = Set(yourRatings.map { rating in
            let name = rating.displayName ?? "Unknown"
            let lat = round(rating.location.latitude * 10000) / 10000
            let lon = round(rating.location.longitude * 10000) / 10000
            return "\(name)_\(lat),\(lon)"
        })
        
        debugPrint("[ProfileView] 📊 Unique places calculation:")
        debugPrint("  Total ratings: \(yourRatings.count)")
        debugPrint("  Unique places: \(uniquePlaces.count)")
        for place in uniquePlaces {
            debugPrint("  - \(place)")
        }
        
        return uniquePlaces.count
    }
    
    private var averageRatingGiven: Double {
        guard !yourRatings.isEmpty else { return 0 }
        let total = yourRatings.reduce(0) { $0 + $1.rating }
        return Double(total) / Double(yourRatings.count)
    }
    
    // MARK: - Profile Photo Functions
    
    /// Load selected profile photo and upload to cloud
    private func loadProfilePhoto(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        debugPrint("[ProfileView] Loading profile photo...")
        isUploadingPhoto = true
        
        do {
            // Load image data
            guard let data = try await item.loadTransferable(type: Data.self) else {
                debugPrint("[ProfileView] ❌ Failed to load image data")
                isUploadingPhoto = false
                return
            }
            
            debugPrint("[ProfileView] ✅ Loaded image data: \(data.count) bytes")
            
            // Upload to Supabase Storage
            let supabase = SupabaseManager.shared
            let profilePhotoUrl = try await supabase.uploadPhoto(data: data, type: .profile)
            
            debugPrint("[ProfileView] ✅ Profile photo uploaded: \(profilePhotoUrl)")
            
            // Save URL to user metadata
            try await updateUserMetadata(profilePhotoUrl: profilePhotoUrl)
            
            // Update local display
            profileImageData = data
            
        } catch {
            debugPrint("[ProfileView] ❌ Failed to upload profile photo: \(error)")
        }
        
        isUploadingPhoto = false
    }
    
    /// Update user's profile photo URL in Supabase auth metadata
    private func updateUserMetadata(profilePhotoUrl: String) async throws {
        let supabase = SupabaseManager.shared
        
        try await supabase.client.auth.update(
            user: UserAttributes(
                data: ["profile_photo_url": .string(profilePhotoUrl)]
            )
        )
        
        debugPrint("[ProfileView] ✅ User metadata updated with profile photo URL")
    }
    
    /// Load existing profile photo from user metadata
    private func loadExistingProfilePhoto() async {
        guard let userId = authViewModel.currentUser?.id,
              let metadata = authViewModel.currentUser?.userMetadata,
              let profilePhotoUrl = metadata["profile_photo_url"]?.stringValue else {
            debugPrint("[ProfileView] No existing profile photo found")
            return
        }
        
        debugPrint("[ProfileView] Loading existing profile photo from: \(profilePhotoUrl)")
        
        // Download photo
        do {
            guard let url = URL(string: profilePhotoUrl) else { return }
            let (data, _) = try await URLSession.shared.data(from: url)
            profileImageData = data
            debugPrint("[ProfileView] ✅ Loaded existing profile photo")
        } catch {
            debugPrint("[ProfileView] ❌ Failed to load existing profile photo: \(error)")
        }
    }
    
    // MARK: - Delete Account
    
    /// Delete user account and all associated data
    private func deleteAccount() async {
        guard let userId = authViewModel.currentUser?.id else {
            debugPrint("[ProfileView] ❌ No user ID found")
            return
        }
        
        debugPrint("[ProfileView] 🗑️ Starting account deletion for user: \(userId)")
        isDeletingAccount = true
        deleteError = nil
        
        do {
            let supabase = SupabaseManager.shared
            
            // Step 1: Delete all user's ratings from database
            debugPrint("[ProfileView] Step 1: Deleting user's ratings...")
            try await supabase.deleteAllUserRatings(userId: userId)
            
            // Step 2: Delete user's photos from storage
            debugPrint("[ProfileView] Step 2: Deleting user's photos...")
            try await supabase.deleteAllUserPhotos(userId: userId)
            
            // Step 3: Delete the user account from Supabase Auth
            debugPrint("[ProfileView] Step 3: Deleting user account...")
            try await supabase.deleteUserAccount()
            
            debugPrint("[ProfileView] ✅ Account deleted successfully!")
            
            // Step 4: Sign out (this will take user back to login screen)
            await authViewModel.signOut()
            
        } catch {
            debugPrint("[ProfileView] ❌ Failed to delete account: \(error)")
            deleteError = "Failed to delete account: \(error.localizedDescription)"
        }
        
        isDeletingAccount = false
    }
    
    // MARK: - Nuclear Reset (Testing Only!)
    
    /// ☢️ NUCLEAR OPTION: Delete ALL data from ALL users
    /// This is for testing purposes only!
    private func nuclearReset() async {
        debugPrint("[ProfileView] ☢️☢️☢️ NUCLEAR RESET INITIATED ☢️☢️☢️")
        isNukingDatabase = true
        
        do {
            let supabase = SupabaseManager.shared
            
            // Step 1: Delete ALL ratings from database
            debugPrint("[ProfileView] ☢️ Step 1: Deleting ALL ratings...")
            try await supabase.deleteAllRatings()
            
            // Step 2: Delete ALL locations from database
            debugPrint("[ProfileView] ☢️ Step 2: Deleting ALL locations...")
            try await supabase.deleteAllLocations()
            
            // Step 3: Clear local cache
            debugPrint("[ProfileView] ☢️ Step 3: Clearing local cache...")
            await model.clearAllData()
            
            // Step 4: Sign out the current user
            debugPrint("[ProfileView] ☢️ Step 4: Signing out current user...")
            try await authViewModel.signOut()
            
            debugPrint("[ProfileView] ✅ NUCLEAR RESET COMPLETE! Database is empty and user signed out.")
            
        } catch {
            debugPrint("[ProfileView] ❌ Nuclear reset failed: \(error)")
        }
        
        isNukingDatabase = false
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundStyle(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

struct RatingRowCard: View {
    let rating: FoodRating
    
    var body: some View {
        HStack(spacing: 12) {
            // Food Photo
            if let image = ImageConverter.makeImage(from: rating.foodImageData) {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(rating.displayName ?? "Unknown")
                    .font(.headline)
                
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= rating.rating ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundStyle(.orange)
                    }
                }
                
                Text(rating.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    ProfileView(model: RatingsViewModel())
        .environment(AuthViewModel())
}

