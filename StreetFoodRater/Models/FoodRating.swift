//
//  FoodRating.swift
//  StreetFoodRater
//
//  Created by GPT on 14/10/2025.
//
//  Explanation Like You Are 10:
//  This file describes the "data card" we use to remember each street food rating.
//  Think of it like a trading card that saves the photos, score, and notes for one food cart.
//

import Foundation
import CoreLocation

/// A helper structure that stores the GPS coordinates where the food cart lives.
/// We keep it separate so that the main rating stays neat and easy to read.
struct FoodLocation: Codable, Equatable {
    /// Latitude is how far up or down on the globe we are.
    let latitude: Double
    /// Longitude is how far left or right on the globe we are.
    let longitude: Double

    /// Converts the simple latitude + longitude into the MapKit coordinate type when we want to show pins on a map.
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

/// `FoodRating` is our main "data card" that remembers everything about one tasty food experience.
/// We make it conform to `Identifiable` so SwiftUI lists can keep track of each card, and `Codable` so we can save + load it easily.
struct FoodRating: Identifiable, Codable, Equatable {
    /// A unique ID so SwiftUI can tell each rating apart. Think of it like giving every card its own name tag.
    let id: UUID
    /// Binary data for the photo of the actual food. We store it as `Data` so we can save it on the device.
    let foodImageData: Data
    /// Binary data for the food cart photo. It is optional because maybe we only snapped the food.
    let cartImageData: Data?
    /// The score from 1 to 10 that says how yummy the food was.
    let rating: Int
    /// Optional note where we can write extra thoughts, smells, or hints for friends.
    let notes: String?
    /// Optional friendly name for the cart or dish. This helps us remember what the photo was about.
    let displayName: String?
    /// Where on Earth we found this food cart so we can show it on the map later.
    let location: FoodLocation
    /// The moment in time when we saved this rating. Awesome for sorting by most recent adventures.
    let createdAt: Date

    /// We use a custom initializer so we can print debug text whenever a rating is created.
    init(
        id: UUID = UUID(),
        foodImageData: Data,
        cartImageData: Data? = nil,
        rating: Int,
        notes: String? = nil,
        displayName: String? = nil,
        location: FoodLocation,
        createdAt: Date = Date()
    ) {
        // Debug print helps us check in the Xcode console that a rating was created successfully.
        debugPrint("[FoodRating] Creating new rating with score \(rating) for \(displayName ?? "Unnamed dish")")

        self.id = id
        self.foodImageData = foodImageData
        self.cartImageData = cartImageData
        self.rating = rating
        self.notes = notes
        self.displayName = displayName
        self.location = location
        self.createdAt = createdAt
    }
}

extension FoodRating {
    /// Helper to turn a MapKit coordinate into our simple `FoodLocation`.
    static func location(from coordinate: CLLocationCoordinate2D) -> FoodLocation {
        FoodLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

