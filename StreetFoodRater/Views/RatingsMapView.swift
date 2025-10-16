//
//  RatingsMapView.swift
//  StreetFoodRater
//
//  Created by GPT on 14/10/2025.
//
//  Kid-Friendly Explanation:
//  This screen shows a big map with pins for every food rating we have created.
//  When you tap a pin, you can jump straight to the detail screen.
//

import SwiftUI
import MapKit
import UIKit

struct RatingsMapView: View {
    let model: RatingsViewModel
    
    /// Location manager from environment (provides GPS location)
    @Environment(LocationManager.self) private var locationManager
    
    /// Helps us decide which sheet (if any) is currently open.
    @State private var activeSheet: ActiveSheet?
    /// Text user types in the floating search field.
    @State private var searchText: String = ""

    /// Keeps track of the rating we tapped so we can navigate to its detail screen.
    @State private var selectedRatingID: UUID?

    var body: some View {
        NavigationStack {
            ZStack {
                mapContent
                overlayUI
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .addRating:
                AddRatingView(model: model)
            case .nearby:
                NearbyPickerSheet(options: nearbyDemoOptions) { option in
                    debugPrint("[RatingsMapView] User picked nearby option: \(option.name)")
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            case .addRatingAtLocation(let location, let name):
                AddRatingView(
                    model: model,
                    prefilledLocation: location,
                    prefilledName: name
                )
            }
        }
        .onAppear {
            debugPrint("[RatingsMapView] Appeared -> requesting model to load ratings.")
            model.loadFromStorageIfNeeded()
        }
    }

    /// The map with markers for each rating.
    private var mapContent: some View {
        Map(position: Binding(
            get: { .region(locationManager.mapRegion) },
            set: { _ in }
        ), selection: $selectedRatingID) {
            ForEach(model.ratings) { rating in
                Annotation(rating.displayName ?? "Yummy Cart", coordinate: rating.location.coordinate) {
                    FoodPinView(rating: rating, isSelected: selectedRatingID == rating.id)
                }
                .tag(rating.id)
            }
            
            // Show user's current location as a blue dot
            if let userLocation = locationManager.currentLocation {
                Annotation("You are here", coordinate: userLocation) {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 10, height: 10)
                        )
                }
            }
        }
        .mapControls {
            MapCompass()
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
        .onChange(of: selectedRatingID) { _, newValue in
            if let ratingID = newValue {
                debugPrint("[RatingsMapView] Pin selected with ID: \(ratingID)")
            }
        }
    }

    /// Combines the top header and floating buttons.
    private var overlayUI: some View {
        VStack(spacing: 0) {
            topHeaderArea
            Spacer()
            
            // Photo preview when a pin is selected
            if let selectedID = selectedRatingID,
               let selectedRating = model.ratings.first(where: { $0.id == selectedID }) {
                photoPreviewCard(for: selectedRating)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 8)
            }
            
            // Floating buttons at bottom
            HStack {
                // Zoom controls on the left
                zoomControls
                    .padding(.leading, 16)
                    .padding(.bottom, 16)
                
                Spacer()
                
                // Nearby button on the right
                nearbyFloatingButton
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
            }
        }
        .padding(.horizontal, 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedRatingID)
    }

    /// Floating + button just above the bottom panel to create a new rating.
    private var addNewRatingButton: some View {
        Button {
            debugPrint("[RatingsMapView] Add (+) tapped - presenting add rating sheet.")
            activeSheet = .addRating
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(LinearGradient(colors: [Color.purple, Color.purple.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                )
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .accessibilityLabel("Add new rating")
    }

    /// Full-width header background that reaches the top; search stays in place.
    private var topHeaderArea: some View {
        VStack(spacing: 6) {
            Text("Street Food Finder")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.purple)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.secondary)
                TextField("Search bars, carts, dishes", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                Button {
                    debugPrint("[RatingsMapView] Filter button tapped with query: \(searchText)")
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.purple)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 4)
            )
        }
        .padding(.top, -48)
        .padding(.bottom, -4)
        .frame(maxWidth: .infinity)
        .background(
            // Big header background that goes to the very top of the screen
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.95))
                .ignoresSafeArea(edges: .top)
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 6)
        )
    }

    /// Zoom controls (bottom left corner)
    private var zoomControls: some View {
        VStack(spacing: 12) {
            // Zoom In button
            Button {
                debugPrint("[RatingsMapView] Zoom in button tapped")
                zoomIn()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(LinearGradient(colors: [Color.purple, Color.purple.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
            }
            
            // Zoom Out button
            Button {
                debugPrint("[RatingsMapView] Zoom out button tapped")
                zoomOut()
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(LinearGradient(colors: [Color.purple, Color.purple.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
            }
        }
    }
    
    /// Floating nearby button (bottom right corner)
    private var nearbyFloatingButton: some View {
        Button {
            debugPrint("[RatingsMapView] Nearby button tapped - presenting nearby picker sheet.")
            activeSheet = .nearby
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .font(.system(size: 16, weight: .bold))
                Text("Nearby")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(Color.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                LinearGradient(colors: [Color.purple, Color.purple.opacity(0.8)], startPoint: .top, endPoint: .bottom)
            )
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 6)
        }
    }
    
    // MARK: - Zoom Functions
    
    /// Zooms the map in (shows less area, more detail)
    private func zoomIn() {
        let currentSpan = locationManager.mapRegion.span
        let newLatitudeDelta = max(currentSpan.latitudeDelta / 2, 0.001) // Min zoom
        let newLongitudeDelta = max(currentSpan.longitudeDelta / 2, 0.001)
        
        locationManager.mapRegion = MKCoordinateRegion(
            center: locationManager.mapRegion.center,
            span: MKCoordinateSpan(latitudeDelta: newLatitudeDelta, longitudeDelta: newLongitudeDelta)
        )
        
        debugPrint("[RatingsMapView] Zoomed in to delta: \(newLatitudeDelta)")
    }
    
    /// Zooms the map out (shows more area, less detail)
    private func zoomOut() {
        let currentSpan = locationManager.mapRegion.span
        let newLatitudeDelta = min(currentSpan.latitudeDelta * 2, 180) // Max zoom out
        let newLongitudeDelta = min(currentSpan.longitudeDelta * 2, 180)
        
        locationManager.mapRegion = MKCoordinateRegion(
            center: locationManager.mapRegion.center,
            span: MKCoordinateSpan(latitudeDelta: newLatitudeDelta, longitudeDelta: newLongitudeDelta)
        )
        
        debugPrint("[RatingsMapView] Zoomed out to delta: \(newLatitudeDelta)")
    }
    
    /// Photo preview card that appears when a pin is tapped
    private func photoPreviewCard(for rating: FoodRating) -> some View {
        VStack(spacing: 12) {
            // Main info card (tappable to view details)
            NavigationLink(value: rating.id) {
                HStack(spacing: 12) {
                    // Food photo
                    if let image = ImageConverter.makeImage(from: rating.foodImageData) {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "fork.knife")
                                    .foregroundStyle(Color.gray)
                            )
                    }
                    
                    // Info section
                    VStack(alignment: .leading, spacing: 6) {
                        Text(rating.displayName ?? "Yummy Cart")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Color.primary)
                            .lineLimit(1)
                        
                        // Star rating
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { index in
                                Image(systemName: index <= rating.rating ? "star.fill" : "star")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.orange)
                            }
                        }
                        
                        Text("Tap to view details")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.secondary)
                    }
                    
                    Spacer()
                    
                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.purple)
                    
                    // Close button
                    Button {
                        debugPrint("[RatingsMapView] Close preview tapped")
                        selectedRatingID = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.gray.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
                )
            }
            
            // "Eaten Here Before?" button
            Button {
                debugPrint("[RatingsMapView] Eaten Here Before button tapped for: \(rating.displayName ?? "Unknown")")
                // Set the active sheet to show AddRatingView
                activeSheet = .addRatingAtLocation(rating.location, name: rating.displayName)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Eaten Here Before?")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(colors: [Color.orange, Color.orange.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .navigationDestination(for: UUID.self) { ratingID in
            if let rating = model.ratings.first(where: { $0.id == ratingID }) {
                RatingDetailView(model: model, rating: rating)
            }
        }
    }

    /// Custom pin view that displays the food photo
    private struct FoodPinView: View {
        let rating: FoodRating
        let isSelected: Bool
        
        var body: some View {
            VStack(spacing: 0) {
                // Food photo in circular frame
                if let image = ImageConverter.makeImage(from: rating.foodImageData) {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: isSelected ? 50 : 40, height: isSelected ? 50 : 40)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.orange, lineWidth: isSelected ? 3 : 2)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                } else {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: isSelected ? 50 : 40, height: isSelected ? 50 : 40)
                        .overlay(
                            Image(systemName: "fork.knife")
                                .foregroundStyle(Color.white)
                                .font(.system(size: 18))
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                
                // Pin point
                Triangle()
                    .fill(isSelected ? Color.orange : Color.orange.opacity(0.9))
                    .frame(width: 12, height: 8)
                    .offset(y: -2)
            }
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
    }
    
    /// Triangle shape for the pin point
    private struct Triangle: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.closeSubpath()
            return path
        }
    }

    private struct TopRoundedRectangle: Shape {
        var cornerRadius: CGFloat

        func path(in rect: CGRect) -> Path {
            let radius = min(cornerRadius, min(rect.width, rect.height) / 2)

            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + radius, y: rect.minY),
                control: CGPoint(x: rect.minX, y: rect.minY)
            )
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY + radius),
                control: CGPoint(x: rect.maxX, y: rect.minY)
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()

            return path
        }
    }


    private var nearbyDemoOptions: [NearbyFoodOption] {
        [
            NearbyFoodOption(
                name: "Jack's Place",
                distanceText: "56m",
                rating: 4.8,
                imageURL: URL(string: "https://images.unsplash.com/photo-1543353071-873f17a7a088?auto=format&fit=crop&w=600&q=80")!
            ),
            NearbyFoodOption(
                name: "Hot & Flame",
                distanceText: "157m",
                rating: 4.0,
                imageURL: URL(string: "https://images.unsplash.com/photo-1499028344343-cd173ffc68a9?auto=format&fit=crop&w=600&q=80")!
            ),
            NearbyFoodOption(
                name: "Alloha",
                distanceText: "215m",
                rating: 4.6,
                imageURL: URL(string: "https://images.unsplash.com/photo-1470337458703-46ad1756a187?auto=format&fit=crop&w=600&q=80")!
            ),
            NearbyFoodOption(
                name: "Juniko's Bar",
                distanceText: "367m",
                rating: 4.7,
                imageURL: URL(string: "https://images.unsplash.com/photo-1466978913421-dad2ebd01d17?auto=format&fit=crop&w=600&q=80")!
            )
        ]
    }
}

#Preview {
    let demoRating = FoodRating(
        foodImageData: UIImage(systemName: "takeoutbag.and.cup.and.straw")!.pngData()!,
        cartImageData: nil,
        rating: 7,
        notes: "Nice noodles",
        displayName: "Noodle Cart",
        location: FoodLocation(latitude: 13.7563, longitude: 100.5018)
    )
    let vm = RatingsViewModel()
    vm.ratings = [demoRating]
    return RatingsMapView(model: vm)
}

// MARK: - Helper Types

/// Keeps track of which sheet the map is showing.
private enum ActiveSheet: Identifiable {
    case addRating
    case nearby
    case addRatingAtLocation(FoodLocation, name: String?)

    var id: Int {
        switch self {
        case .addRating:
            return 0
        case .nearby:
            return 1
        case .addRatingAtLocation:
            return 2
        }
    }
}

/// Dummy row information for the nearby picker.
private struct NearbyFoodOption: Identifiable {
    let id = UUID()
    let name: String
    let distanceText: String
    let rating: Double
    let imageURL: URL
}

/// Sheet that shows pretend nearby food results.
private struct NearbyPickerSheet: View {
    /// Pretend options that the user can pick.
    let options: [NearbyFoodOption]
    /// Called when the kid taps one of the rows.
    let onSelect: (NearbyFoodOption) -> Void

    @Environment(\.dismiss) private var dismiss

    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 16) {
                    ForEach(options) { option in
                        Button {
                            debugPrint("[NearbyPickerSheet] User tapped \(option.name)")
                            onSelect(option)
                            dismiss()
                        } label: {
                            NearbyFoodCard(option: option)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Nearby")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.purple)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        debugPrint("[NearbyPickerSheet] Done tapped.")
                        dismiss()
                    }
                    .foregroundStyle(Color.purple)
                }
            }
        }
    }

    /// Single grid card for a nearby option.
    private struct NearbyFoodCard: View {
        let option: NearbyFoodOption

        var body: some View {
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 0) {
                    // Image section - no spacing, flush to top
                    AsyncImage(url: option.imageURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            Color.gray.opacity(0.2)
                                .overlay(
                                    Image(systemName: "fork.knife")
                                        .font(.system(size: 28, weight: .regular))
                                        .foregroundStyle(Color.gray)
                                )
                        @unknown default:
                            Color.gray.opacity(0.2)
                        }
                    }
                    .frame(width: geometry.size.width, height: 120)
                    .clipped()

                    // Content section
                    VStack(alignment: .leading, spacing: 6) {
                        // Name and distance in same row
                        HStack(alignment: .top) {
                            Text(option.name)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color.primary)
                                .lineLimit(1)
                            
                            Spacer(minLength: 4)
                            
                            Text(option.distanceText)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(Color.primary)
                        }
                        
                        // Rating section
                        HStack(spacing: 2) {
                            ForEach(0..<5, id: \.self) { index in
                                Image(systemName: starImage(for: index, rating: option.rating))
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.orange)
                            }
                            Text(String(format: "%.1f", option.rating))
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(Color.primary)
                                .padding(.leading, 4)
                        }
                        
                        // Tags section (placeholder)
                        Text("elegant, steak, wine, ro...")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Color.secondary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(height: 220)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
        }

        /// Selects the SF Symbol that best represents the rating for a given star slot.
        private func starImage(for index: Int, rating: Double) -> String {
            let threshold = rating - Double(index)
            if threshold >= 1 {
                return "star.fill"
            } else if threshold >= 0.5 {
                return "star.leadinghalf.filled"
            } else {
                return "star"
            }
        }
    }
}
