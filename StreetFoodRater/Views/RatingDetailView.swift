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
                notesSection
                mapSection
            }
            .padding()
        }
        .navigationTitle(rating.displayName ?? "Street Food Detail")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    debugPrint("[RatingDetailView] Delete button tapped for ID: \(rating.id)")
                    model.removeRating(by: rating.id)
                    dismiss()
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
    }

    // MARK: - Sections

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
            Text("Score")
                .font(.headline)
            Text("\(rating.rating)/10")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.orange)

            Text("Rated on \(DateFormatterUtility.string(from: rating.createdAt))")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    /// Shows notes if the user wrote any.
    private var notesSection: some View {
        Group {
            if let notes = rating.notes {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                    Text(notes)
                        .font(.body)
                }
            }
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
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 16))
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

#Preview {
    let demoRating = FoodRating(
        foodImageData: UIImage(systemName: "takeoutbag.and.cup.and.straw")!.pngData()!,
        cartImageData: UIImage(systemName: "tram")!.pngData(),
        rating: 9,
        notes: "Super tasty mango sticky rice with extra coconut sauce!",
        displayName: "Mango Sticky Rice Cart",
        location: FoodLocation(latitude: 13.7563, longitude: 100.5018)
    )
    return RatingDetailView(model: RatingsViewModel(), rating: demoRating)
}


