//
//  AddRatingView.swift
//  StreetFoodRater
//
//  Created by GPT on 14/10/2025.
//
//  Kid-Friendly Explanation:
//  This screen is where we create a brand-new food rating card.
//  We let the user pick photos, choose a score, add notes, and pick the location.
//  Then we hand the finished card to the `RatingsViewModel` brain to store it.
//

import SwiftUI
import PhotosUI
import CoreLocation
import MapKit

struct AddRatingView: View {
    /// We hold onto the main brain so we can add the new rating when the user taps save.
    let model: RatingsViewModel
    /// This environment helper lets us close the screen once we finish.
    @Environment(\.dismiss) private var dismiss

    // MARK: - Form State (View Layer)

    /// Stores the selected photo for the food as `PhotosPickerItem` until we convert it to Data.
    @State private var selectedFoodPhoto: PhotosPickerItem?
    /// Actual data for the food photo so we can send it to the model.
    @State private var foodImageData: Data?

    /// Stores the selected cart photo.
    @State private var selectedCartPhoto: PhotosPickerItem?
    /// Actual data for the cart photo.
    @State private var cartImageData: Data?

    /// Keeps track of the rating slider value.
    @State private var ratingValue: Double = 5

    /// Optional text for the user to type notes.
    @State private var notes: String = ""

    /// Optional name for the dish or cart.
    @State private var displayName: String = ""

    /// The map region we show in the picker.
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 13.7563, longitude: 100.5018),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    /// The exact coordinate the user picks.
    @State private var selectedCoordinate: CLLocationCoordinate2D?

    /// Tracks whether we show an alert for validation errors.
    @State private var showValidationAlert = false
    /// Message for the validation alert.
    @State private var validationMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                photoSection
                ratingSection
                notesSection
                locationSection
            }
            .navigationTitle("New Food Rating")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        debugPrint("[AddRatingView] User cancelled creating a rating.")
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        debugPrint("[AddRatingView] Save button tapped.")
                        createRating()
                    }
                    .disabled(foodImageData == nil || selectedCoordinate == nil)
                }
            }
            .alert("Hold on!", isPresented: $showValidationAlert, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text(validationMessage)
            })
        }
        .onChange(of: selectedFoodPhoto) { _, newValue in
            Task {
                await loadImageData(from: newValue, label: "food") { data in
                    debugPrint("[AddRatingView] Updating foodImageData binding on main thread.")
                    foodImageData = data
                }
            }
        }
        .onChange(of: selectedCartPhoto) { _, newValue in
            Task {
                await loadImageData(from: newValue, label: "cart") { data in
                    debugPrint("[AddRatingView] Updating cartImageData binding on main thread.")
                    cartImageData = data
                }
            }
        }
    }

    // MARK: - Form Sections

    /// Section that handles picking photos.
    private var photoSection: some View {
        Section("Photos") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Food Photo (Required)")
                    .font(.subheadline)
                PhotosPicker(selection: $selectedFoodPhoto, matching: .images) {
                    photoPreview(imageData: foodImageData, placeholderSystemName: "fork.knife")
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Cart Photo (Optional)")
                    .font(.subheadline)
                PhotosPicker(selection: $selectedCartPhoto, matching: .images) {
                    photoPreview(imageData: cartImageData, placeholderSystemName: "tram")
                }
            }
        }
    }

    /// Shows the mini photo or a placeholder icon.
    private func photoPreview(imageData: Data?, placeholderSystemName: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 150)
            if let data = imageData, let image = ImageConverter.makeImage(from: data) {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 12) {
                    Image(systemName: placeholderSystemName)
                        .font(.system(size: 40))
                    Text("Tap to choose photo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// Section for rating slider and name field.
    private var ratingSection: some View {
        Section("Rating") {
            Stepper(value: $ratingValue, in: 1...10, step: 1) {
                Text("Score: \(Int(ratingValue))/10")
                    .font(.headline)
            }

            TextField("Dish or cart name (optional)", text: $displayName)
        }
    }

    /// Section for free-form notes.
    private var notesSection: some View {
        Section("Notes") {
            TextEditor(text: $notes)
                .frame(height: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4))
                )
        }
    }

    /// Section that shows a mini map to pick the location.
    private var locationSection: some View {
        Section("Cart Location") {
            Text("Drag the map and tap to set where the food cart lives.")
                .font(.caption)
                .foregroundColor(.secondary)

            MapReader { proxy in
                Map(initialPosition: .region(mapRegion))
                    .mapControls {
                        MapUserLocationButton()
                        MapCompass()
                    }
                    /// We use a drag gesture with zero distance so we can grab the tap location (TapGesture doesn't give us a CGPoint).
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                let tapPoint = value.location
                                if let coordinate = proxy.convert(tapPoint, from: .local) {
                                    debugPrint("[AddRatingView] Map tapped at \(coordinate.latitude), \(coordinate.longitude)")
                                    selectedCoordinate = coordinate
                                } else {
                                    debugPrint("[AddRatingView] Failed to convert tap point \(tapPoint) into coordinate.")
                                }
                            }
                    )
                    .overlay(alignment: .center) {
                        if let coordinate = selectedCoordinate {
                            MapPinView(coordinate: coordinate)
                        } else {
                            Text("Tap map to drop a pin")
                                .padding(8)
                                .background(.thinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
            }
            .frame(height: 200)
        }
    }

    // MARK: - Create Rating

    /// Validates the form and tells the view model to add the rating.
    private func createRating() {
        guard let foodImageData else {
            validationMessage = "Please choose a photo of the food so we remember what it looks like."
            showValidationAlert = true
            return
        }

        guard let coordinate = selectedCoordinate else {
            validationMessage = "Please tap the map to choose where the cart is located."
            showValidationAlert = true
            return
        }

        let rating = FoodRating(
            foodImageData: foodImageData,
            cartImageData: cartImageData,
            rating: Int(ratingValue),
            notes: notes.isEmpty ? nil : notes,
            displayName: displayName.isEmpty ? nil : displayName,
            location: FoodLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        )

        debugPrint("[AddRatingView] Created rating -> sending to model.")
        model.addRating(rating)
        dismiss()
    }

    /// Loads the chosen photo into Data so we can store it.
    private func loadImageData(
        from item: PhotosPickerItem?,
        label: String,
        assign: @Sendable @escaping (Data?) -> Void
    ) async {
        guard let item else {
            await MainActor.run {
                assign(nil)
            }
            return
        }

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                debugPrint("[AddRatingView] Loaded \(label) photo data. Size: \(data.count) bytes")
                await MainActor.run {
                    assign(data)
                }
            }
        } catch {
            debugPrint("[AddRatingView] Failed to load \(label) photo: \(error)")
            await MainActor.run {
                assign(nil)
            }
        }
    }
}

/// A simple view that displays a map pin at the chosen coordinate.
private struct MapPinView: View {
    let coordinate: CLLocationCoordinate2D

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.red)
            Text(String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude))
                .font(.caption2)
                .padding(4)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}

#Preview {
    AddRatingView(model: RatingsViewModel())
}

