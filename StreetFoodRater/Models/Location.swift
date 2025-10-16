//
//  Location.swift
//  StreetFoodRater
//
//  Created by GPT on 16/10/2025.
//
//  Kid-Friendly Explanation:
//  This represents a physical food cart location that multiple people can rate.
//  Think of it like a pin on a map that everyone shares - the cart itself stays in one place,
//  but many people can visit it and give their own ratings!
//

import Foundation
import CoreLocation

/// Represents a shared food cart location that multiple users can rate
struct Location: Codable, Identifiable, Equatable {
    /// Unique ID from Supabase database
    let id: UUID
    /// Name of the food cart or stand
    let name: String?
    /// GPS coordinates - how far up/down on Earth
    let latitude: Double
    /// GPS coordinates - how far left/right on Earth
    let longitude: Double
    /// When this location was first added to the database
    let createdAt: Date
    
    /// Converts to MapKit coordinate for showing on map
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// Custom coding keys to match Supabase database column names (snake_case)
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case latitude
        case longitude
        case createdAt = "created_at"
    }
    
    /// Helper to create a Location from our old FoodLocation
    static func from(foodLocation: FoodLocation, name: String?) -> Location {
        Location(
            id: UUID(),
            name: name,
            latitude: foodLocation.latitude,
            longitude: foodLocation.longitude,
            createdAt: Date()
        )
    }
}

