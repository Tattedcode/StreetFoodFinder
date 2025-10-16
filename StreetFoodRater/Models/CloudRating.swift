//
//  CloudRating.swift
//  StreetFoodRater
//
//  Created by GPT on 16/10/2025.
//
//  Kid-Friendly Explanation:
//  This is like FoodRating, but designed for the cloud!
//  Instead of storing the actual photo data (which is big and slow),
//  we store URLs (web addresses) that point to photos in Supabase cloud storage.
//  Think of it like saving a link to a YouTube video instead of downloading the whole video!
//

import Foundation

/// Represents a rating stored in Supabase cloud database
struct CloudRating: Codable, Identifiable, Equatable {
    /// Unique ID from Supabase
    let id: UUID
    /// Which user created this rating (their user ID)
    let userId: UUID
    /// Which location this rating is for (links to locations table)
    let locationId: UUID
    /// Star rating from 1-5
    let rating: Int
    /// User's written review (optional)
    let reviewText: String?
    /// URL to the food photo in Supabase Storage (like: "https://supabase.../food.jpg")
    let foodPhotoUrl: String?
    /// URL to the cart photo in Supabase Storage (optional)
    let cartPhotoUrl: String?
    /// When this rating was created
    let createdAt: Date
    
    /// Custom coding keys to match Supabase database column names (snake_case)
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case locationId = "location_id"
        case rating
        case reviewText = "review_text"
        case foodPhotoUrl = "food_photo_url"
        case cartPhotoUrl = "cart_photo_url"
        case createdAt = "created_at"
    }
}

/// Extended data that combines rating with location info for easier display
struct RatingWithLocation: Identifiable, Equatable {
    let id: UUID
    let rating: CloudRating
    let location: Location
    let userName: String?  // Email or username of who rated it
    
    /// Is this rating created by the current user?
    func isOwnedBy(userId: UUID) -> Bool {
        rating.userId == userId
    }
}

