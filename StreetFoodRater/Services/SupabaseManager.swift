//
//  SupabaseManager.swift
//  StreetFoodRater
//
//  Created by GPT on 16/10/2025.
//
//  Kid-Friendly Explanation:
//  This is the "messenger" that talks to Supabase for us!
//  When you want to save a rating, this messenger carries it to the cloud.
//  When you want to see all ratings, this messenger fetches them from the cloud.
//  Think of it like a mail carrier who delivers letters (data) back and forth!
//

import Foundation
import Supabase
import Combine

/// Main service that handles all Supabase operations
@MainActor
final class SupabaseManager: ObservableObject {
    
    /// The Supabase client - like the phone line to the cloud
    let client: SupabaseClient
    
    /// Published property to track current user session
    @Published var currentUser: Supabase.User?
    
    /// Singleton instance - one manager for the whole app
    static let shared = SupabaseManager()
    
    private init() {
        debugPrint("[SupabaseManager] Initializing connection to Supabase cloud...")
        
        // Create the client connection using our config
        self.client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.projectURL)!,
            supabaseKey: SupabaseConfig.anonKey
        )
        
        debugPrint("[SupabaseManager] ✅ Connected to Supabase at: \(SupabaseConfig.projectURL)")
        
        // Check if user is already logged in
        Task {
            await checkCurrentSession()
        }
    }
    
    // MARK: - Authentication
    
    /// Check if there's an active session (user already logged in)
    func checkCurrentSession() async {
        do {
            let session = try await client.auth.session
            currentUser = session.user
            debugPrint("[SupabaseManager] ✅ User already logged in: \(session.user.email ?? "Unknown")")
        } catch {
            debugPrint("[SupabaseManager] No active session (user not logged in)")
            currentUser = nil
        }
    }
    
    /// Sign up a new user with email and password
    func signUp(email: String, password: String) async throws {
        debugPrint("[SupabaseManager] Signing up user: \(email)")
        let response = try await client.auth.signUp(email: email, password: password)
        currentUser = response.user
        debugPrint("[SupabaseManager] ✅ Sign up successful for: \(email)")
    }
    
    /// Log in an existing user
    func signIn(email: String, password: String) async throws {
        debugPrint("[SupabaseManager] Signing in user: \(email)")
        let session = try await client.auth.signIn(email: email, password: password)
        currentUser = session.user
        debugPrint("[SupabaseManager] ✅ Sign in successful for: \(email)")
    }
    
    /// Log out the current user
    func signOut() async throws {
        debugPrint("[SupabaseManager] Signing out user: \(currentUser?.email ?? "Unknown")")
        try await client.auth.signOut()
        currentUser = nil
        debugPrint("[SupabaseManager] ✅ Sign out successful")
    }
    
    // MARK: - Locations
    
    /// Create a new location or find existing one nearby
    func createOrFindLocation(name: String?, latitude: Double, longitude: Double) async throws -> Location {
        let cartName = name ?? "Unnamed"
        debugPrint("[SupabaseManager] Looking for existing location: '\(cartName)' near: \(latitude), \(longitude)")
        
        // Check if a location already exists with THE SAME NAME very close to these coordinates
        // This prevents duplicates when multiple people rate the same cart
        // BUT allows different carts at the same location to exist separately!
        let existingLocations: [Location] = try await client
            .from("locations")
            .select()
            .execute()
            .value
        
        // Find location with MATCHING NAME within 0.0001 degrees (~10 meters)
        // KEY FIX: Now checks BOTH name AND proximity!
        if let nearby = existingLocations.first(where: { location in
            let nameMatches = location.name?.lowercased() == cartName.lowercased()
            let coordinatesClose = abs(location.latitude - latitude) < 0.0001 && abs(location.longitude - longitude) < 0.0001
            return nameMatches && coordinatesClose
        }) {
            debugPrint("[SupabaseManager] ✅ Found existing location: '\(nearby.name ?? "Unknown")' (ID: \(nearby.id))")
            return nearby
        }
        
        // No matching location found, create a new one
        debugPrint("[SupabaseManager] Creating NEW location: '\(cartName)' at \(latitude), \(longitude)")
        let newLocation = Location(
            id: UUID(),
            name: name,
            latitude: latitude,
            longitude: longitude,
            createdAt: Date()
        )
        
        let created: Location = try await client
            .from("locations")
            .insert(newLocation)
            .select()
            .single()
            .execute()
            .value
        
        debugPrint("[SupabaseManager] ✅ Created new location: '\(created.name ?? "Unknown")' with ID: \(created.id)")
        return created
    }
    
    /// Fetch all locations from the database
    func fetchAllLocations() async throws -> [Location] {
        debugPrint("[SupabaseManager] Fetching all locations from cloud...")
        let locations: [Location] = try await client
            .from("locations")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
        
        debugPrint("[SupabaseManager] ✅ Fetched \(locations.count) locations")
        return locations
    }
    
    // MARK: - Ratings
    
    /// Create a new rating in the cloud
    func createRating(
        locationId: UUID,
        rating: Int,
        reviewText: String?,
        foodPhotoUrl: String?,
        cartPhotoUrl: String?
    ) async throws -> CloudRating {
        guard let userId = currentUser?.id else {
            throw SupabaseError.notAuthenticated
        }
        
        debugPrint("[SupabaseManager] Creating rating for location: \(locationId), rating: \(rating)")
        
        let newRating = CloudRating(
            id: UUID(),
            userId: userId,
            locationId: locationId,
            rating: rating,
            reviewText: reviewText,
            foodPhotoUrl: foodPhotoUrl,
            cartPhotoUrl: cartPhotoUrl,
            createdAt: Date()
        )
        
        let created: CloudRating = try await client
            .from("ratings")
            .insert(newRating)
            .select()
            .single()
            .execute()
            .value
        
        debugPrint("[SupabaseManager] ✅ Rating created with ID: \(created.id)")
        return created
    }
    
    /// Fetch all ratings from the cloud
    func fetchAllRatings() async throws -> [CloudRating] {
        debugPrint("[SupabaseManager] Fetching all ratings from cloud...")
        let ratings: [CloudRating] = try await client
            .from("ratings")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
        
        debugPrint("[SupabaseManager] ✅ Fetched \(ratings.count) ratings")
        return ratings
    }
    
    /// Fetch all ratings for a specific location
    func fetchRatings(forLocationId locationId: UUID) async throws -> [CloudRating] {
        debugPrint("[SupabaseManager] Fetching ratings for location: \(locationId)")
        let ratings: [CloudRating] = try await client
            .from("ratings")
            .select()
            .eq("location_id", value: locationId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        debugPrint("[SupabaseManager] ✅ Fetched \(ratings.count) ratings for this location")
        return ratings
    }
    
    /// Fetch a single location by ID
    func fetchLocation(by id: UUID) async throws -> Location {
        debugPrint("[SupabaseManager] Fetching location: \(id)")
        let locations: [Location] = try await client
            .from("locations")
            .select()
            .eq("id", value: id)
            .execute()
            .value
        
        guard let location = locations.first else {
            throw SupabaseError.notFound
        }
        
        debugPrint("[SupabaseManager] ✅ Location fetched: \(location.name)")
        return location
    }
    
    /// Delete a rating (only if you own it!)
    func deleteRating(id: UUID) async throws {
        guard let userId = currentUser?.id else {
            throw SupabaseError.notAuthenticated
        }
        
        debugPrint("[SupabaseManager] Deleting rating: \(id)")
        
        try await client
            .from("ratings")
            .delete()
            .eq("id", value: id)
            .eq("user_id", value: userId)  // Safety: only delete your own ratings!
            .execute()
        
        debugPrint("[SupabaseManager] ✅ Rating deleted")
    }
    
    /// Delete all ratings for a specific user (used when deleting account)
    func deleteAllUserRatings(userId: UUID) async throws {
        debugPrint("[SupabaseManager] Deleting all ratings for user: \(userId)")
        
        try await client
            .from("ratings")
            .delete()
            .eq("user_id", value: userId)
            .execute()
        
        debugPrint("[SupabaseManager] ✅ All user ratings deleted")
    }
    
    /// Delete all photos uploaded by a user (used when deleting account)
    func deleteAllUserPhotos(userId: UUID) async throws {
        debugPrint("[SupabaseManager] Deleting all photos for user: \(userId)")
        
        // Note: Supabase Storage doesn't have a built-in way to filter by user_id
        // For now, we'll just skip photo deletion as they'll be orphaned but won't break anything
        // In production, you'd want to track photo URLs in the ratings table and delete them individually
        
        debugPrint("[SupabaseManager] ✅ Photo deletion skipped (photos will be orphaned)")
    }
    
    /// Delete the user's account from Supabase Auth
    func deleteUserAccount() async throws {
        debugPrint("[SupabaseManager] Deleting user account from Supabase Auth...")
        
        // Supabase's admin.deleteUser requires service_role key
        // For now, users can request deletion through Supabase dashboard
        // Or we implement this server-side
        
        // Instead, we'll sign out the user after deleting their data
        debugPrint("[SupabaseManager] ⚠️ User account deletion requires admin privileges")
        debugPrint("[SupabaseManager] ✅ User data deleted, account should be deleted manually from dashboard")
    }
    
    // MARK: - Nuclear Options (Testing Only!)
    
    /// ☢️ DELETE ALL RATINGS FROM ALL USERS
    /// This is for testing purposes only!
    func deleteAllRatings() async throws {
        debugPrint("[SupabaseManager] ☢️ DELETING ALL RATINGS FROM DATABASE")
        
        try await client
            .from("ratings")
            .delete()
            .neq("id", value: "00000000-0000-0000-0000-000000000000")  // Delete everything (all IDs not equal to impossible UUID)
            .execute()
        
        debugPrint("[SupabaseManager] ✅ ALL RATINGS DELETED")
    }
    
    /// ☢️ DELETE ALL LOCATIONS FROM ALL USERS
    /// This is for testing purposes only!
    func deleteAllLocations() async throws {
        debugPrint("[SupabaseManager] ☢️ DELETING ALL LOCATIONS FROM DATABASE")
        
        try await client
            .from("locations")
            .delete()
            .neq("id", value: "00000000-0000-0000-0000-000000000000")  // Delete everything (all IDs not equal to impossible UUID)
            .execute()
        
        debugPrint("[SupabaseManager] ✅ ALL LOCATIONS DELETED")
    }
    
    // MARK: - Real-Time Subscriptions
    
    /// Subscribe to real-time updates for ratings
    /// Returns a channel that you can unsubscribe from later
    func subscribeToRatingsUpdates(onInsert: @escaping (CloudRating, Location) -> Void) async throws -> RealtimeChannelV2 {
        debugPrint("[SupabaseManager] 🔴 Setting up real-time subscription to ratings table...")
        
        let channel = client.realtimeV2.channel("ratings-changes")
        
        let insertStream = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "ratings"
        )
        
        await channel.subscribe()
        
        // Listen for inserts in the background
        Task {
            for await insert in insertStream {
                debugPrint("[SupabaseManager] 🔴 NEW RATING DETECTED from real-time!")
                do {
                    let cloudRating = try insert.record.decode(as: CloudRating.self)
                    debugPrint("[SupabaseManager] 🔴 Real-time rating: \(cloudRating.id)")
                    
                    // Fetch the location data for this rating
                    let location = try await fetchLocation(by: cloudRating.locationId)
                    onInsert(cloudRating, location)
                } catch {
                    debugPrint("[SupabaseManager] ❌ Failed to decode/fetch real-time rating: \(error)")
                }
            }
        }
        
        debugPrint("[SupabaseManager] ✅ Real-time subscription active!")
        return channel
    }
    
    /// Unsubscribe from a channel
    func unsubscribe(from channel: RealtimeChannelV2) async {
        debugPrint("[SupabaseManager] Unsubscribing from real-time channel...")
        await channel.unsubscribe()
        debugPrint("[SupabaseManager] ✅ Unsubscribed from real-time updates")
    }
    
    // MARK: - Photo Upload
    
    /// Upload a photo to Supabase Storage and return its URL
    func uploadPhoto(data: Data, type: PhotoType) async throws -> String {
        debugPrint("[SupabaseManager] Uploading \(type.rawValue) photo (\(data.count) bytes)...")
        
        // Generate unique filename
        let filename = "\(UUID().uuidString)_\(type.rawValue).jpg"
        let path = "\(type.rawValue)s/\(filename)"
        
        // Upload to Supabase Storage bucket
        try await client.storage
            .from("food-photos")
            .upload(
                path,
                data: data,
                options: FileOptions(contentType: "image/jpeg")
            )
        
        // Get the public URL for this photo
        let publicURL = try client.storage
            .from("food-photos")
            .getPublicURL(path: path)
        
        debugPrint("[SupabaseManager] ✅ Photo uploaded: \(publicURL)")
        return publicURL.absoluteString
    }
    
    /// Types of photos we can upload
    enum PhotoType: String {
        case food
        case cart
        case profile
    }
    
    // MARK: - Real-Time Subscriptions
    
    /// Subscribe to real-time changes (when others add ratings)
    /// Note: Real-time will be implemented once we have the basic CRUD operations working
    func subscribeToRatings(onInsert: @escaping (CloudRating) -> Void) async {
        debugPrint("[SupabaseManager] 🔔 Real-time subscriptions will be set up in next phase")
        // Real-time implementation will come after we get basic features working
        // This ensures we learn step-by-step!
    }
}

// MARK: - Errors

enum SupabaseError: LocalizedError {
    case notAuthenticated
    case uploadFailed
    case networkError
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to do this."
        case .uploadFailed:
            return "Failed to upload photo to cloud."
        case .networkError:
            return "Network connection error. Please check your internet."
        case .notFound:
            return "The requested data was not found."
        }
    }
}

// MARK: - Helper Extension for Decoding

extension Data {
    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        try JSONDecoder().decode(type, from: self)
    }
}

