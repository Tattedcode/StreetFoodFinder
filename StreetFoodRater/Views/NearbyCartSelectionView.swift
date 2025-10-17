//
//  NearbyCartSelectionView.swift
//  StreetFoodRater
//
//  Created by GPT on 16/10/2025.
//
//  Kid-Friendly Explanation:
//  When you press the + button, this screen pops up and asks:
//  "Are you eating at any of these carts nearby?"
//  It shows photos of carts within 50 meters so you can pick the right one!
//  This prevents duplicate pins and ensures everyone rates the correct cart!
//

import SwiftUI
import MapKit

struct NearbyCartSelectionView: View {
    let model: RatingsViewModel
    let userLocation: CLLocationCoordinate2D
    @Environment(\.dismiss) private var dismiss
    
    /// When user selects a cart, this closure is called
    let onCartSelected: (LocationGroup) -> Void
    /// When user taps "None of these", this closure is called
    let onCreateNew: () -> Void
    
    /// Find all carts within 50 meters of user's current location
    private var nearbyCarts: [LocationGroup] {
        model.locationGroups.filter { group in
            let cartLocation = CLLocation(
                latitude: group.coordinate.latitude,
                longitude: group.coordinate.longitude
            )
            let userLoc = CLLocation(
                latitude: userLocation.latitude,
                longitude: userLocation.longitude
            )
            
            let distance = userLoc.distance(from: cartLocation)
            debugPrint("[NearbyCartSelection] Cart '\(group.name)' is \(Int(distance))m away")
            return distance <= 50 // Within 50 meters
        }
        .sorted { cart1, cart2 in
            // Sort by distance (closest first)
            let loc1 = CLLocation(latitude: cart1.coordinate.latitude, longitude: cart1.coordinate.longitude)
            let loc2 = CLLocation(latitude: cart2.coordinate.latitude, longitude: cart2.coordinate.longitude)
            let userLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
            return userLoc.distance(from: loc1) < userLoc.distance(from: loc2)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header text
                    VStack(spacing: 8) {
                        Text("🍜")
                            .font(.system(size: 60))
                        Text("Are you eating at any of these carts?")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color.purple)
                            .multilineTextAlignment(.center)
                        Text("We found \(nearbyCarts.count) \(nearbyCarts.count == 1 ? "cart" : "carts") nearby")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                    
                    // Grid of nearby carts
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(nearbyCarts) { cart in
                            NearbyCartCard(cart: cart) {
                                debugPrint("[NearbyCartSelection] User selected: \(cart.name)")
                                onCartSelected(cart)
                                dismiss()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // "None of these" button
                    Button {
                        debugPrint("[NearbyCartSelection] User tapped 'None of these'")
                        onCreateNew()
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("None of these")
                                    .font(.system(size: 17, weight: .semibold))
                                Text("Create a new cart pin")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.white.opacity(0.8))
                            }
                        }
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.purple, Color.purple.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        debugPrint("[NearbyCartSelection] User cancelled")
                        dismiss()
                    }
                    .foregroundStyle(Color.purple)
                }
            }
        }
    }
}

/// Card showing a single nearby cart
private struct NearbyCartCard: View {
    let cart: LocationGroup
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Cart photo
                if let latestRating = cart.latestRating,
                   let image = ImageConverter.makeImage(from: latestRating.foodImageData) {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 120)
                        .overlay(
                            Image(systemName: "fork.knife")
                                .font(.system(size: 40))
                                .foregroundStyle(Color.gray)
                        )
                }
                
                // Cart info
                VStack(alignment: .leading, spacing: 4) {
                    Text(cart.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.primary)
                        .lineLimit(2)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.orange)
                        Text(String(format: "%.1f", cart.averageRating))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.primary)
                        Text("(\(cart.reviewCount))")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.secondary)
                    }
                    
                    // Distance (if we want to show it later)
                    // Text("~25m away")
                    //     .font(.caption2)
                    //     .foregroundStyle(Color.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

