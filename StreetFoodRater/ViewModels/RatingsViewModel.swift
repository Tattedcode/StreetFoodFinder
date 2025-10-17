//
//  RatingsViewModel.swift
//  StreetFoodRater
//
//  Updated for Supabase Cloud Storage on 16/10/2025
//
//  Kid-Friendly Explanation:
//  This is the "brain" that manages all food ratings!
//  OLD: Saved ratings to a file on YOUR phone only
//  NEW: Saves ratings to Supabase cloud so EVERYONE can see them!
//  Think of it like upgrading from a personal diary to a shared Instagram feed!

import Foundation
import Observation
import Supabase
import CoreLocation

@Observable
@MainActor
final class RatingsViewModel {

    // All food rating cards (combines cloud ratings + locations for easy display)
    var ratings: [FoodRating] = [] {
        didSet { debugPrint("[RatingsViewModel] Ratings changed. Total now: \(ratings.count)") }
    }
    
    /// Is the app currently loading ratings from the cloud?
    var isLoading = false
    
    /// Error message if something goes wrong
    var errorMessage: String?
    
    /// Reference to Supabase manager
    private let supabase = SupabaseManager.shared
    
    /// Real-time subscription channel
    private var realtimeChannel: RealtimeChannelV2?

    init() {
        debugPrint("[RatingsViewModel] Initialized with cloud storage")
        // Load ratings from cloud when app starts
        Task {
            await loadFromCloud()
            await startRealtimeUpdates()
        }
    }
    
    deinit {
        debugPrint("[RatingsViewModel] Deinitializing - unsubscribing from real-time updates")
        Task { @MainActor in
            if let channel = realtimeChannel {
                await supabase.unsubscribe(from: channel)
            }
        }
    }

    /// Add a new rating to the cloud (called from AddRatingView)
    func addRating(_ rating: FoodRating) async {
        debugPrint("[RatingsViewModel] Adding rating to cloud: \(rating.id)")
        debugPrint("  📍 SAVING coordinates: lat=\(rating.location.latitude), lon=\(rating.location.longitude)")
        isLoading = true
        errorMessage = nil
        
        do {
            // Step 1: Upload food photo to cloud storage
            guard let foodPhotoUrl = try await uploadPhoto(rating.foodImageData, type: .food) else {
                throw SupabaseError.uploadFailed
            }
            
            // Step 2: Upload cart photo if it exists
            let cartPhotoUrl: String? = if let cartData = rating.cartImageData {
                try await uploadPhoto(cartData, type: .cart)
            } else {
                nil
            }
            
            // Step 3: Create or find the location
            let location = try await supabase.createOrFindLocation(
                name: rating.displayName,
                latitude: rating.location.latitude,
                longitude: rating.location.longitude
            )
            
            // Step 4: Create the rating in cloud database
            let cloudRating = try await supabase.createRating(
                locationId: location.id,
                rating: rating.rating,
                reviewText: rating.notes,
                foodPhotoUrl: foodPhotoUrl,
                cartPhotoUrl: cartPhotoUrl
            )
            
            debugPrint("[RatingsViewModel] ✅ Rating saved to cloud!")
            
            // Step 5: Don't add to local array - let real-time updates handle it
            // This prevents duplication when real-time subscription receives the same rating
            debugPrint("[RatingsViewModel] ⏳ Waiting for real-time update to add rating to UI...")
            
            // Step 6: Refresh from cloud to get everyone's ratings
            await loadFromCloud()
            
        } catch {
            debugPrint("[RatingsViewModel] ❌ Failed to save rating: \(error)")
            errorMessage = "Failed to save rating: \(error.localizedDescription)"
        }
        
        isLoading = false
    }

    /// Remove a rating from the cloud
    func removeRating(by ratingID: UUID) async {
        debugPrint("[RatingsViewModel] Removing rating: \(ratingID)")
        isLoading = true
        
        do {
            try await supabase.deleteRating(id: ratingID)
            ratings.removeAll { $0.id == ratingID }
            debugPrint("[RatingsViewModel] ✅ Rating deleted from cloud")
        } catch {
            debugPrint("[RatingsViewModel] ❌ Failed to delete rating: \(error)")
            errorMessage = "Failed to delete rating: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// ☢️ CLEAR ALL DATA (Nuclear option for testing)
    func clearAllData() async {
        debugPrint("[RatingsViewModel] ☢️ CLEARING ALL LOCAL DATA")
        await MainActor.run {
            ratings.removeAll()
            debugPrint("[RatingsViewModel] ✅ Local cache cleared")
        }
    }

    /// Load all ratings from the cloud (everyone's ratings!)
    func loadFromCloud() async {
        debugPrint("[RatingsViewModel] Loading ratings from cloud...")
        isLoading = true
        errorMessage = nil
        
        // MIGRATION: Clear existing ratings to prevent mixing old (no userId) and new (with userId) data
        await MainActor.run {
            ratings.removeAll()
            debugPrint("[RatingsViewModel] 🧹 Cleared existing ratings for migration to userId-based system")
        }
        
        do {
            // Fetch all cloud ratings
            let cloudRatings = try await supabase.fetchAllRatings()
            
            // Fetch all locations
            let locations = try await supabase.fetchAllLocations()
            
            // Convert cloud ratings to FoodRating format for display
            var convertedRatings: [FoodRating] = []
            
            for cloudRating in cloudRatings {
                // Find the matching location
                guard let location = locations.first(where: { $0.id == cloudRating.locationId }) else {
                    continue
                }
                
                // Download photo data from URL
                guard let foodPhotoData = await downloadPhoto(from: cloudRating.foodPhotoUrl) else {
                    continue
                }
                
                let cartPhotoData = await downloadPhoto(from: cloudRating.cartPhotoUrl)
                
                // Convert to FoodRating for display
                debugPrint("[RatingsViewModel] 📍 Converting rating for: \(location.name ?? "Unknown")")
                debugPrint("  Database lat: \(location.latitude), lon: \(location.longitude)")
                
                let foodRating = FoodRating(
                    id: cloudRating.id,
                    userId: cloudRating.userId,
                    foodImageData: foodPhotoData,
                    cartImageData: cartPhotoData,
                    rating: cloudRating.rating,
                    notes: cloudRating.reviewText,
                    displayName: location.name ?? "Unknown",
                    location: FoodLocation(
                        latitude: location.latitude,
                        longitude: location.longitude
                    ),
                    createdAt: cloudRating.createdAt
                )
                
                debugPrint("  FoodLocation created: lat=\(foodRating.location.latitude), lon=\(foodRating.location.longitude)")
                debugPrint("  CLLocationCoordinate2D: \(foodRating.location.coordinate.latitude), \(foodRating.location.coordinate.longitude)")
                
                convertedRatings.append(foodRating)
            }
            
            ratings = convertedRatings
            debugPrint("[RatingsViewModel] ✅ Loaded \(ratings.count) ratings from cloud")
            
        } catch {
            debugPrint("[RatingsViewModel] ❌ Failed to load ratings: \(error)")
            errorMessage = "Failed to load ratings: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    /// Upload photo to Supabase Storage and return URL
    private func uploadPhoto(_ data: Data?, type: SupabaseManager.PhotoType) async throws -> String? {
        guard let data = data else { return nil }
        return try await supabase.uploadPhoto(data: data, type: type)
    }
    
    /// Download photo data from URL
    private func downloadPhoto(from urlString: String?) async -> Data? {
        guard let urlString = urlString,
              let url = URL(string: urlString) else {
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        } catch {
            debugPrint("[RatingsViewModel] Failed to download photo: \(error)")
            return nil
        }
    }
    
    /// Legacy method for compatibility - no longer saves locally
    func loadFromStorageIfNeeded() {
        debugPrint("[RatingsViewModel] Legacy load method called - using cloud storage instead")
        Task {
            await loadFromCloud()
        }
    }
    
    /// Debug method to clear all ratings
    func removeAllRatingsForDebug() async {
        debugPrint("[RatingsViewModel] ⚠️ Clearing all local ratings (cloud data remains)")
        ratings.removeAll()
    }
    
    // MARK: - Real-Time Updates
    
    /// Start listening for real-time updates from Supabase
    private func startRealtimeUpdates() async {
        debugPrint("[RatingsViewModel] 🔴 Starting real-time updates...")
        
        do {
            realtimeChannel = try await supabase.subscribeToRatingsUpdates { [weak self] cloudRating, location in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    debugPrint("[RatingsViewModel] 🔴 NEW RATING RECEIVED via real-time!")
                    await self.handleNewRating(cloudRating, location: location)
                }
            }
            debugPrint("[RatingsViewModel] ✅ Real-time updates active!")
        } catch {
            debugPrint("[RatingsViewModel] ❌ Failed to start real-time updates: \(error)")
        }
    }
    
    /// Handle a new rating received from real-time subscription
    private func handleNewRating(_ cloudRating: CloudRating, location: Location) async {
        // Check if we already have this rating (avoid duplicates)
        // Check by ID first, then by content to be extra safe
        if ratings.contains(where: { $0.id == cloudRating.id }) {
            debugPrint("[RatingsViewModel] 🔴 Rating already exists (by ID), skipping")
            return
        }
        
        // Additional check: same user, same location, same rating, same time (within 1 minute)
        let duplicateByContent = ratings.contains { existingRating in
            existingRating.userId == cloudRating.userId &&
            abs(existingRating.location.latitude - location.latitude) < 0.0001 &&
            abs(existingRating.location.longitude - location.longitude) < 0.0001 &&
            existingRating.rating == cloudRating.rating &&
            abs(existingRating.createdAt.timeIntervalSince(cloudRating.createdAt)) < 60
        }
        
        if duplicateByContent {
            debugPrint("[RatingsViewModel] 🔴 Rating already exists (by content), skipping")
            return
        }
        
        debugPrint("[RatingsViewModel] 🔴 Adding new rating to map: \(cloudRating.id)")
        
        // Download photos
        let foodPhoto = await downloadPhoto(from: cloudRating.foodPhotoUrl)
        let cartPhoto = await downloadPhoto(from: cloudRating.cartPhotoUrl)
        
        // Only add if we successfully downloaded the food photo (required!)
        guard let foodPhoto = foodPhoto else {
            debugPrint("[RatingsViewModel] ❌ Failed to download food photo for new rating")
            return
        }
        
        // Convert Location to FoodLocation
        let foodLocation = FoodLocation(
            latitude: location.latitude,
            longitude: location.longitude
        )
        
        // Convert to FoodRating model
        let newRating = FoodRating(
            id: cloudRating.id,
            userId: cloudRating.userId,
            foodImageData: foodPhoto,
            cartImageData: cartPhoto,
            rating: cloudRating.rating,
            notes: cloudRating.reviewText,
            displayName: location.name,
            location: foodLocation,
            createdAt: cloudRating.createdAt
        )
        
        // Add to our local array
        ratings.append(newRating)
        
        debugPrint("[RatingsViewModel] ✅ New rating added! Total ratings: \(ratings.count)")
    }
}



