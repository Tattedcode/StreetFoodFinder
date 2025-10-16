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

    init() {
        debugPrint("[RatingsViewModel] Initialized with cloud storage")
        // Load ratings from cloud when app starts
        Task {
            await loadFromCloud()
        }
    }

    /// Add a new rating to the cloud (called from AddRatingView)
    func addRating(_ rating: FoodRating) async {
        debugPrint("[RatingsViewModel] Adding rating to cloud: \(rating.id)")
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
            
            // Step 5: Add to local array for instant display (optimistic update)
            ratings.insert(rating, at: 0)
            
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

    /// Load all ratings from the cloud (everyone's ratings!)
    func loadFromCloud() async {
        debugPrint("[RatingsViewModel] Loading ratings from cloud...")
        isLoading = true
        errorMessage = nil
        
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
                let foodRating = FoodRating(
                    id: cloudRating.id,
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
}



