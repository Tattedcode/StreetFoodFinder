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
    /// All reviews for this location
    @State private var allReviews: [ReviewData] = []
    /// Show all reviews or just first 3
    @State private var showAllReviews = false
    /// Loading state
    @State private var isLoadingReviews = false

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
                prefilledName: rating.displayName,
                hideMapSection: true  // Hide map when rating existing cart
            )
        }
        .task {
            await loadAllReviews()
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

    /// Shows all photos from all users for this location in a scrollable collection.
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photos")
                .font(.headline)
            
            // Get all photos from all users for this location
            let allPhotos = getAllPhotosForLocation()
            
            if allPhotos.isEmpty {
                placeholderPhoto(systemName: "photo")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(allPhotos.enumerated()), id: \.offset) { index, photoData in
                            if let image = ImageConverter.makeImage(from: photoData) {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 200, height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        // Photo number indicator
                                        VStack {
                                            HStack {
                                                Spacer()
                                                Text("\(index + 1)")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundStyle(.white)
                                                    .padding(6)
                                                    .background(Color.black.opacity(0.6))
                                                    .clipShape(Circle())
                                            }
                                            Spacer()
                                        }
                                        .padding(8)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
    
    /// Gets all photos from all users for this specific location
    private func getAllPhotosForLocation() -> [Data] {
        // Find the location group that contains this rating
        guard let locationGroup = model.locationGroups.first(where: { group in
            // Check if this rating belongs to this location group
            group.ratings.contains { $0.id == rating.id }
        }) else {
            debugPrint("[RatingDetailView] ❌ Could not find location group for rating \(rating.id)")
            return []
        }
        
        debugPrint("[RatingDetailView] 📸 Found location group '\(locationGroup.name)' with \(locationGroup.ratings.count) ratings")
        
        // Collect all photos from all ratings in this location group
        var allPhotos: [Data] = []
        
        for rating in locationGroup.ratings {
            // Add food photo
            allPhotos.append(rating.foodImageData)
            
            // Add cart photo if it exists
            if let cartData = rating.cartImageData {
                allPhotos.append(cartData)
            }
        }
        
        debugPrint("[RatingDetailView] 📸 Total photos collected: \(allPhotos.count)")
        return allPhotos
    }

    /// Shows the rating score and when we created it.
    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Get all ratings for this location (not just those with text)
            let allRatingsForLocation = getAllRatingsForLocation()
            
            // Overall average rating for this location
            if allRatingsForLocation.count > 1 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overall Rating")
                        .font(.headline)
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.orange)
                            Text(String(format: "%.1f", averageRatingFromAllRatings))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        
                        Text("from \(allRatingsForLocation.count) reviews")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                    .padding(.vertical, 4)
            }
            
            // Individual user's rating
            VStack(alignment: .leading, spacing: 8) {
                Text(allRatingsForLocation.count > 1 ? "Your Rating" : "Rating")
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
    }
    
    /// Calculate average rating from all reviews (text reviews only)
    private var averageRating: Double {
        guard !allReviews.isEmpty else { return 0 }
        let total = allReviews.reduce(0) { $0 + $1.rating }
        return Double(total) / Double(allReviews.count)
    }
    
    /// Calculate average rating from all ratings (including those without text)
    private var averageRatingFromAllRatings: Double {
        let allRatings = getAllRatingsForLocation()
        guard !allRatings.isEmpty else { return 0 }
        let total = allRatings.reduce(0) { $0 + $1.rating }
        return Double(total) / Double(allRatings.count)
    }
    
    /// Gets all ratings for this specific location (including those without text)
    private func getAllRatingsForLocation() -> [FoodRating] {
        // Find the location group that contains this rating
        guard let locationGroup = model.locationGroups.first(where: { group in
            // Check if this rating belongs to this location group
            group.ratings.contains { $0.id == rating.id }
        }) else {
            debugPrint("[RatingDetailView] ❌ Could not find location group for rating \(rating.id)")
            return []
        }
        
        debugPrint("[RatingDetailView] 📊 Found location group '\(locationGroup.name)' with \(locationGroup.ratings.count) total ratings")
        return locationGroup.ratings
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
            HStack {
                Text("Reviews")
                    .font(.headline)
                Spacer()
                if isLoadingReviews {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if allReviews.isEmpty {
                // Empty state if no reviews
                VStack(spacing: 8) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.gray.opacity(0.5))
                    Text("No reviews yet")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.secondary)
                    Text("Be the first to review this place!")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                // Show reviews
                let reviewsToShow = showAllReviews ? allReviews : Array(allReviews.prefix(3))
                
                ForEach(reviewsToShow) { review in
                    ReviewCard(review: Review(
                        id: review.id,
                        userName: review.userEmail,
                        rating: review.rating,
                        date: review.date,
                        comment: review.comment
                    ))
                }
                
                // "More (X)" button if there are more than 3 reviews
                if allReviews.count > 3 && !showAllReviews {
                    Button {
                        withAnimation {
                            showAllReviews = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "chevron.down")
                            Text("More (\(allReviews.count - 3))")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.purple)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                } else if showAllReviews {
                    // "Show Less" button
                    Button {
                        withAnimation {
                            showAllReviews = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: "chevron.up")
                            Text("Show Less")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.purple)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }
    
    // MARK: - Data Loading
    
    /// Fetch all reviews for this location from Supabase
    private func loadAllReviews() async {
        debugPrint("[RatingDetailView] Loading all reviews for location: \(rating.location.latitude), \(rating.location.longitude)")
        isLoadingReviews = true
        
        // Find all ratings at this exact location (within 10 meters)
        let locationRatings = model.ratings.filter { r in
            let latDiff = abs(r.location.latitude - rating.location.latitude)
            let lonDiff = abs(r.location.longitude - rating.location.longitude)
            return latDiff < 0.0001 && lonDiff < 0.0001
        }
        
        // Convert to ReviewData with user emails
        allReviews = locationRatings.compactMap { rating in
            guard let comment = rating.notes, !comment.isEmpty else { return nil }
            
            return ReviewData(
                id: rating.id,
                userEmail: "User", // We'll improve this later when we track user_id
                rating: rating.rating,
                date: rating.createdAt,
                comment: comment
            )
        }
        
        debugPrint("[RatingDetailView] ✅ Loaded \(allReviews.count) reviews")
        isLoadingReviews = false
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

/// Review data structure for multiple users
private struct ReviewData: Identifiable {
    let id: UUID
    let userEmail: String
    let rating: Int
    let date: Date
    let comment: String
}

/// Review display structure
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

// #Preview {
//     let demoRating: FoodRating = FoodRating(
//         userId: UUID(), // Demo user ID
//         foodImageData: UIImage(systemName: "takeoutbag.and.cup.and.straw")!.pngData()!,
//         cartImageData: UIImage(systemName: "tram")!.pngData(),
//         rating: 5,
//         notes: "Super tasty mango sticky rice with extra coconut sauce!",
//         displayName: "Mango Sticky Rice Cart",
//         location: FoodLocation(latitude: 13.7563, longitude: 100.5018)
//     )
//     RatingDetailView(model: RatingsViewModel(), rating: demoRating)
// }


