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
    /// Optional pre-filled location (when "Eaten Here?" is tapped)
    let prefilledLocation: FoodLocation?
    /// Optional pre-filled name (when "Eaten Here?" is tapped)
    let prefilledName: String?
    
    /// This environment helper lets us close the screen once we finish.
    @Environment(\.dismiss) private var dismiss
    
    /// Location manager to get current GPS location
    @Environment(LocationManager.self) private var locationManager

    // MARK: - Form State (View Layer)
    
    init(model: RatingsViewModel, prefilledLocation: FoodLocation? = nil, prefilledName: String? = nil) {
        self.model = model
        self.prefilledLocation = prefilledLocation
        self.prefilledName = prefilledName
    }

    /// Stores the selected photo for the food as `PhotosPickerItem` until we convert it to Data.
    @State private var selectedFoodPhoto: PhotosPickerItem?
    /// Actual data for the food photo so we can send it to the model.
    @State private var foodImageData: Data?

    /// Stores the selected cart photo.
    @State private var selectedCartPhoto: PhotosPickerItem?
    /// Actual data for the cart photo.
    @State private var cartImageData: Data?

    /// Keeps track of the star rating value (1-5).
    @State private var ratingValue: Int = 0

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
                nameSection
                ratingSection
                photoSection
                notesSection
                locationSection
            }
            // Make the entire form's text purple to match home
            .foregroundStyle(Color.purple)
            .tint(.purple)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("New Food Rating")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.purple)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        debugPrint("[AddRatingView] User cancelled creating a rating.")
                        dismiss()
                    }
                    .foregroundStyle(Color.purple)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        debugPrint("[AddRatingView] Save button tapped.")
                        createRating()
                    }
                    .disabled(foodImageData == nil || selectedCoordinate == nil || ratingValue == 0)
                    .foregroundStyle(Color.purple)
                }
            }
            .alert("Hold on!", isPresented: $showValidationAlert, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text(validationMessage)
            })
            .alert("Error", isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            ), actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text(model.errorMessage ?? "Unknown error")
            })
            .overlay {
                if model.isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.purple)
                            Text("Uploading to cloud...")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.95))
                        )
                        .shadow(radius: 20)
                    }
                }
            }
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
        .onAppear {
            // Pre-fill location if provided (when "Eaten Here?" is tapped)
            if let location = prefilledLocation {
                selectedCoordinate = location.coordinate
                mapRegion = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
                debugPrint("[AddRatingView] Pre-filled location: \(location.latitude), \(location.longitude)")
            }
            // Otherwise, use current GPS location automatically!
            else if let currentLocation = locationManager.currentLocation {
                selectedCoordinate = currentLocation
                mapRegion = MKCoordinateRegion(
                    center: currentLocation,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
                debugPrint("[AddRatingView] ✅ Using current GPS location: \(currentLocation.latitude), \(currentLocation.longitude)")
            }
            
            // Pre-fill name if provided
            if let name = prefilledName {
                displayName = name
                debugPrint("[AddRatingView] Pre-filled name: \(name)")
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
                    .foregroundStyle(Color.purple)
                PhotosPicker(selection: $selectedFoodPhoto, matching: .images) {
                    photoPreview(imageData: foodImageData, placeholderSystemName: "fork.knife")
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Cart Photo (Optional)")
                    .font(.subheadline)
                    .foregroundStyle(Color.purple)
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
                        .foregroundStyle(Color.purple)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// Section for star rating only.
    private var ratingSection: some View {
        Section("Rating") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Tap to rate")
                    .font(.subheadline)
                    .foregroundStyle(Color.purple)
                
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { index in
                        Button {
                            debugPrint("[AddRatingView] User tapped star \(index), current value: \(ratingValue)")
                            // If tapping the same star, deselect it
                            if ratingValue == index {
                                ratingValue = 0
                            } else {
                                ratingValue = index
                            }
                        } label: {
                            Image(systemName: index <= ratingValue ? "star.fill" : "star")
                                .font(.system(size: 32))
                                .foregroundStyle(Color.orange)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
                
                if ratingValue > 0 {
                    Text("\(ratingValue) star\(ratingValue == 1 ? "" : "s")")
                        .font(.headline)
                        .foregroundStyle(Color.purple)
                }
            }
        }
    }
    
    /// Section for store or food name.
    private var nameSection: some View {
        Section("Name") {
            TextField("Store or food name", text: $displayName)
                .foregroundStyle(Color.purple)
        }
    }

    /// Section for free-form review.
    private var notesSection: some View {
        Section("Review") {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $notes)
                    .frame(height: 120)
                    .foregroundColor(.purple)
                
                // Placeholder text when notes is empty
                if notes.isEmpty {
                    Text("This is optional")
                        .foregroundColor(Color(.placeholderText))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4))
            )
        }
    }

    /// Section that shows a mini map to pick the location.
    private var locationSection: some View {
        Section("Cart Location") {
            if selectedCoordinate != nil {
                Text("✅ Location set! (Tap map to change)")
                    .font(.caption)
                    .foregroundStyle(Color.green)
            } else {
                Text("📍 Using your current location (tap map to change)")
                    .font(.caption)
                    .foregroundStyle(Color.purple)
            }

            MapReader { proxy in
                Map(initialPosition: .region(mapRegion))
                    .mapControls {
                        MapUserLocationButton()
                        MapCompass()
                    }
                    .mapStyle(.standard(pointsOfInterest: .excludingAll))
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
                                .foregroundStyle(Color.purple)
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
        
        guard ratingValue > 0 else {
            validationMessage = "Please tap the stars to give a rating."
            showValidationAlert = true
            return
        }

        let rating = FoodRating(
            foodImageData: foodImageData,
            cartImageData: cartImageData,
            rating: ratingValue,
            notes: notes.isEmpty ? nil : notes,
            displayName: displayName.isEmpty ? nil : displayName,
            location: FoodLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        )

        debugPrint("[AddRatingView] Created rating with \(ratingValue) stars -> uploading to cloud!")
        
        // Upload to cloud (async operation)
        Task {
            await model.addRating(rating)
            dismiss()
        }
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
