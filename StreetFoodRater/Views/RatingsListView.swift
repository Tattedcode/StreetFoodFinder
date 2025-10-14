//
//  RatingsListView.swift
//  StreetFoodRater
//
//  Created by GPT on 14/10/2025.
//
//  Kid-Friendly Explanation:
//  This file draws the main screen that shows a list of all our food rating cards.
//  It is part of the "View" layer in MVVM. It talks to the `RatingsViewModel` brain to know what to show.
//

import SwiftUI

struct RatingsListView: View {
    /// `model` is our view model. It gives the list the data it should show.
    /// We mark it as `let` because SwiftUI automatically watches it thanks to `@Observable`.
    let model: RatingsViewModel

    var body: some View {
        NavigationStack {
            Group {
                if model.ratings.isEmpty {
                    emptyState
                } else {
                    ratingsList
                }
            }
            .navigationTitle("Street Food Rater")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        RatingsMapView(model: model)
                    } label: {
                        Label("Map", systemImage: "map")
                    }
                }
            }
        }
        .onAppear {
            debugPrint("[RatingsListView] Appeared -> asking model to load saved ratings.")
            model.loadFromStorageIfNeeded()
        }
    }

    /// Shown when the user has not rated any food yet.
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "takeoutbag.and.cup.and.straw")
                .font(.system(size: 64))
                .foregroundColor(.orange)
            Text("No yummy stories yet!")
                .font(.headline)
            Text("Tap the + button to rate your first street food adventure.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    /// The list that shows every rating card.
    private var ratingsList: some View {
        List(model.ratings) { rating in
            NavigationLink(value: rating.id) {
                RatingRowView(rating: rating)
            }
        }
        .navigationDestination(for: UUID.self) { ratingID in
            if let rating = model.ratings.first(where: { $0.id == ratingID }) {
                RatingDetailView(model: model, rating: rating)
            } else {
                Text("Rating not found")
            }
        }
    }

}

/// One row in the main list. Think of it as the mini preview of a food rating card.
private struct RatingRowView: View {
    let rating: FoodRating

    var body: some View {
        HStack(spacing: 12) {
            foodThumbnail
            VStack(alignment: .leading, spacing: 6) {
                Text(rating.displayName ?? "Unnamed dish")
                    .font(.headline)
                Text("Score: \(rating.rating)/10")
                    .font(.subheadline)
                    .foregroundColor(.orange)
                Text(DateFormatterUtility.string(from: rating.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }

    /// Turns the stored food photo data into a small image.
    private var foodThumbnail: some View {
        Group {
            if let image = ImageConverter.makeImage(from: rating.foodImageData) {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "leaf")
                    .resizable()
                    .scaledToFit()
                    .padding(12)
                    .foregroundColor(.green)
            }
        }
        .frame(width: 60, height: 60)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    let demoRating = FoodRating(
        foodImageData: UIImage(systemName: "takeoutbag.and.cup.and.straw")!.pngData()!,
        cartImageData: nil,
        rating: 8,
        notes: "Super spicy pad thai!",
        displayName: "Pad Thai Tuk-Tuk",
        location: FoodLocation(latitude: 13.7563, longitude: 100.5018)
    )
    let viewModel = RatingsViewModel()
    viewModel.ratings = [demoRating]
    return RatingsListView(model: viewModel)
}

