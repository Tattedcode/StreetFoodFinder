//
//  LocationGroup.swift
//  StreetFoodRater
//
//  Created by GPT on 16/10/2025.
//
//  Kid-Friendly Explanation:
//  This groups multiple ratings for THE SAME CART together!
//  If 5 people rate "Mama's Pad Thai Cart", this combines them
//  and calculates the average: (5+4+5+3+4) ÷ 5 = 4.2 stars
//
//  IMPORTANT: Groups by CART NAME + location, so different carts
//  sitting next to each other (like in a Thai food market) stay separate!
//

import Foundation
import CoreLocation

/// Represents a location with multiple ratings from different users
struct LocationGroup: Identifiable {
    let id: String // Generated from coordinates
    let name: String
    let coordinate: CLLocationCoordinate2D
    let ratings: [FoodRating]
    
    /// Average rating (e.g., 4.2 stars)
    var averageRating: Double {
        guard !ratings.isEmpty else { return 0 }
        let total = ratings.reduce(0) { $0 + $1.rating }
        return Double(total) / Double(ratings.count)
    }
    
    /// Total number of ratings
    var reviewCount: Int {
        ratings.count
    }
    
    /// Number of ratings with written reviews (text comments)
    var reviewsWithTextCount: Int {
        ratings.filter { $0.notes != nil && !$0.notes!.isEmpty }.count
    }
    
    /// Most recent rating (for photo display)
    var latestRating: FoodRating? {
        ratings.max(by: { $0.createdAt < $1.createdAt })
    }
    
    /// All reviews with text
    var reviewsWithText: [FoodRating] {
        ratings.filter { $0.notes != nil && !$0.notes!.isEmpty }
    }
}

extension RatingsViewModel {
    /// Group ratings by NAME + location (within 10 meters)
    /// This ensures different carts at the same location stay separate!
    var locationGroups: [LocationGroup] {
        var groups: [String: [FoodRating]] = [:]
        
        // Group ratings by cart name AND approximate location
        for rating in ratings {
            // Get the cart/food name
            let name = rating.displayName ?? "Unknown"
            
            // Round coordinates to 4 decimal places (~10 meter precision)
            // This handles GPS drift - same cart might have slightly different coordinates
            let lat = round(rating.location.latitude * 10000) / 10000
            let lon = round(rating.location.longitude * 10000) / 10000
            
            // KEY CHANGE: Include name in the grouping key!
            // This keeps "Mama's Pad Thai" separate from "Som Tam Stand"
            // even if they're right next to each other
            let key = "\(name)_\(lat),\(lon)"
            
            // DEBUG: Print grouping info
            debugPrint("[LocationGroup] 🔑 Grouping rating:")
            debugPrint("  Name: '\(name)'")
            debugPrint("  Original GPS: \(rating.location.latitude), \(rating.location.longitude)")
            debugPrint("  Rounded GPS: \(lat), \(lon)")
            debugPrint("  Key: '\(key)'")
            
            if groups[key] == nil {
                groups[key] = []
            }
            groups[key]?.append(rating)
        }
        
        // Convert to LocationGroup objects
        return groups.compactMap { key, ratings in
            guard let first = ratings.first else { return nil }
            
            return LocationGroup(
                id: key,
                name: first.displayName ?? "Unknown",
                coordinate: first.location.coordinate,
                ratings: ratings
            )
        }
    }
}

