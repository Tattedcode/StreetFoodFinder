//
//  RatingDetailView.swift
//  StreetFoodRater
//
//  Created by GPT on 14/10/2025.
//
//  Kid-Friendly Explanation:
//  When we tap a row in the list, this screen shows everything about that street food adventure.
//  We can see the big photos, the score, notes, and even delete the rating if we made a mistake.
//

import SwiftUI
import MapKit

struct RatingDetailView: View {
    /// Same brain as the other screens so we can delete or modify the rating.
    let model: RatingsViewModel
    /// The rating card we want to show.
    let rating: FoodRating
    /// Environment helper that lets us go back to the previous screen.
    @Environment(\.dismiss) private var dismiss
    /// Controls whether to show the "Eaten Here?" add rating sheet
    @State private var showEatenHereSheet = false

    /// We build a MapCameraPosition once so the map stays focused on the rating location.
    private var mapPosition: MapCameraPosition {
        .region(
            MKCoordinateRegion(
                center: rating.location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                photoSection
                ratingSection
                eatenHereButton
                mapSection
                reviewsSection
            }
            .padding()
        }
        .navigationTitle(rating.displayName ?? "Street Food Detail")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    debugPrint("[RatingDetailView] Delete button tapped for ID: \(rating.id)")
                    Task {
                        await model.removeRating(by: rating.id)
                        dismiss()
                    }
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .sheet(isPresented: $showEatenHereSheet) {
            AddRatingView(
                model: model,
                prefilledLocation: rating.location,
                prefilledName: rating.displayName
            )
        }
    }

    // MARK: - Sections
    
    /// "Eaten Here Before?" button at the top
    private var eatenHereButton: some View {
        Button {
            debugPrint("[RatingDetailView] Eaten Here Before button tapped for: \(rating.displayName ?? "Unknown")")
            showEatenHereSheet = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                Text("Eaten Here Before?")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
            }
            .foregroundStyle(Color.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.orange, Color.orange.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.orange.opacity(0.35), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    /// Shows the main food photo and optional cart photo.
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photos")
                .font(.headline)

            if let image = ImageConverter.makeImage(from: rating.foodImageData) {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxHeight: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                placeholderPhoto(systemName: "fork.knife")
            }

            if let cartData = rating.cartImageData,
               let cartImage = ImageConverter.makeImage(from: cartData) {
                cartImage
                    .resizable()
                    .scaledToFill()
                    .frame(maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    /// Shows the rating score and when we created it.
    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Rating")
                .font(.headline)
            
            // Star rating display
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= rating.rating ? "star.fill" : "star")
                        .font(.system(size: 28))
                        .foregroundColor(.orange)
                }
            }

            Text("Rated on \(DateFormatterUtility.string(from: rating.createdAt))")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    /// Shows the map with a pin at the food location.
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cart Location")
                .font(.headline)

            Map(initialPosition: mapPosition) {
                Marker(rating.displayName ?? "Food Cart", coordinate: rating.location.coordinate)
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    /// Shows the user's review
    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reviews")
                .font(.headline)
            
            // Show user's review if they wrote one
            if let userReview = rating.notes, !userReview.isEmpty {
                ReviewCard(review: Review(
                    id: rating.id,
                    userName: "You",
                    rating: rating.rating,
                    date: rating.createdAt,
                    comment: userReview
                ))
            } else {
                // Empty state if no review
                VStack(spacing: 8) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.gray.opacity(0.5))
                    Text("No review yet")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.secondary)
                    Text("Add your thoughts about this place")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            }
        }
    }

    /// Placeholder when an image fails to load.
    private func placeholderPhoto(systemName: String) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemGray6))
            .frame(height: 200)
            .overlay(
                Image(systemName: systemName)
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
            )
    }
}

// MARK: - Review Components

/// Review data structure
private struct Review {
    let id: UUID
    let userName: String
    let rating: Int
    let date: Date
    let comment: String
}

/// Review card component
private struct ReviewCard: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // User name and date
            HStack {
                Text(review.userName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.primary)
                
                Spacer()
                
                Text(timeAgo(from: review.date))
                    .font(.system(size: 13))
                    .foregroundStyle(Color.secondary)
            }
            
            // Star rating
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= review.rating ? "star.fill" : "star")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.orange)
                }
            }
            
            // Comment
            Text(review.comment)
                .font(.system(size: 15))
                .foregroundStyle(Color.primary)
                .lineLimit(3)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    /// Convert date to "2 days ago" format
    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: date, to: now)
        
        if let days = components.day, days > 0 {
            return days == 1 ? "1 day ago" : "\(days) days ago"
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        } else {
            return "Just now"
        }
    }
}

#Preview {
    let demoRating = FoodRating(
        foodImageData: UIImage(systemName: "takeoutbag.and.cup.and.straw")!.pngData()!,
        cartImageData: UIImage(systemName: "tram")!.pngData(),
        rating: 5,
        notes: "Super tasty mango sticky rice with extra coconut sauce!",
        displayName: "Mango Sticky Rice Cart",
        location: FoodLocation(latitude: 13.7563, longitude: 100.5018)
    )
    return RatingDetailView(model: RatingsViewModel(), rating: demoRating)
}


