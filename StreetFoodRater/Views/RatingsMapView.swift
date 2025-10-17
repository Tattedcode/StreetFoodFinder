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
    
    /// Selected location group (for showing all ratings at a location)
    @State private var selectedLocationGroupID: String?
    
    /// Filtered location groups based on search text
    var filteredLocationGroups: [LocationGroup] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return model.locationGroups
        }
        return model.locationGroups.filter { group in
            group.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                mapContent
                overlayUI
            }
            .navigationDestination(for: UUID.self) { ratingID in
                if let rating = model.ratings.first(where: { $0.id == ratingID }) {
                    RatingDetailView(model: model, rating: rating)
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .addRating:
                AddRatingView(model: model)
            case .addRatingAtLocation(let location, let name):
                AddRatingView(
                    model: model,
                    prefilledLocation: location,
                    prefilledName: name,
                    hideMapSection: true  // Hide map when rating existing cart
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
        ), selection: $selectedLocationGroupID) {
            // Show grouped locations with average ratings (filtered by search)
            ForEach(filteredLocationGroups) { group in
                Annotation(group.name, coordinate: group.coordinate) {
                    LocationGroupPinView(
                        group: group,
                        isSelected: selectedLocationGroupID == group.id
                    )
                }
                .tag(group.id)
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
        .onTapGesture { location in
            debugPrint("[RatingsMapView] 🗺️ Map tapped at screen location: \(location)")
            handleMapTap(at: location)
        }
        .mapControls {
            MapCompass()
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
        .onChange(of: selectedLocationGroupID) { _, newValue in
            if let groupID = newValue {
                debugPrint("[RatingsMapView] Location group selected with ID: \(groupID)")
            }
        }
    }

    /// Combines the top header and floating buttons.
    private var overlayUI: some View {
        VStack(spacing: 0) {
            topHeaderArea
            Spacer()
            
            // Photo preview when a pin is selected
            if let selectedGroupID = selectedLocationGroupID,
               let selectedGroup = model.locationGroups.first(where: { $0.id == selectedGroupID }) {
                locationGroupPreviewCard(for: selectedGroup)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 8)
            }
            
            // Floating buttons at bottom
            HStack {
                Spacer()
                
                // Zoom controls on the right (where nearby button used to be)
                zoomControls
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
            // Title with logo
            HStack(spacing: 8) {
                Image("streetfoodlogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                
                Text("Street Food Finder")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.purple)
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.secondary)
                
                TextField("Search bars, carts, dishes", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                
                // Clear button when search text is present
                if !searchText.isEmpty {
                    Button {
                        debugPrint("[RatingsMapView] Clear search tapped")
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.gray.opacity(0.6))
                    }
                    .buttonStyle(.plain)
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

    /// Zoom controls (bottom right corner) - Horizontal layout
    private var zoomControls: some View {
        HStack(spacing: 12) {
            // Zoom Out button (left)
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
                            .fill(LinearGradient(colors: [Color.purple, Color.purple.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
            }
            
            // Zoom In button (right)
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
                            .fill(LinearGradient(colors: [Color.purple, Color.purple.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
            }
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
    
    /// Location group preview card showing average rating
    private func locationGroupPreviewCard(for group: LocationGroup) -> some View {
        VStack(spacing: 12) {
            // Main info card (tappable to view first rating's details)
            if let firstRating = group.latestRating {
                NavigationLink(value: firstRating.id) {
                    HStack(spacing: 12) {
                        // Food photo
                        if let image = ImageConverter.makeImage(from: firstRating.foodImageData) {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Info section
                        VStack(alignment: .leading, spacing: 6) {
                            Text(group.name)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(Color.primary)
                                .lineLimit(1)
                            
                            // Average rating
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.orange)
                                Text(String(format: "%.1f", group.averageRating))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color.primary)
                                Text("(\(group.reviewCount) \(group.reviewCount == 1 ? "review" : "reviews"))")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.secondary)
                            }
                            
                            Text("Tap to view all reviews")
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
                            selectedLocationGroupID = nil
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
                    debugPrint("[RatingsMapView] Eaten Here Before button tapped for: \(group.name)")
                    activeSheet = .addRatingAtLocation(firstRating.location, name: group.name)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Eaten Here Before?")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [Color.orange, Color.orange.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedLocationGroupID)
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
    }

    /// Custom pin view that displays the food photo
    /// Pin view for location groups showing average rating
    private struct LocationGroupPinView: View {
        let group: LocationGroup
        let isSelected: Bool
        
        var body: some View {
            VStack(spacing: 0) {
                // Food photo in circular frame
                if let latestRating = group.latestRating,
                   let image = ImageConverter.makeImage(from: latestRating.foodImageData) {
                    ZStack(alignment: .topTrailing) {
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
                        
                        // Average rating badge
                        if group.reviewCount > 1 {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 8))
                                Text(String(format: "%.1f", group.averageRating))
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.orange)
                            )
                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                            .offset(x: 8, y: -8)
                        }
                    }
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
    
    // MARK: - Map Interaction
    
    /// Handle when user taps on the map to create a new rating
    private func handleMapTap(at location: CGPoint) {
        debugPrint("[RatingsMapView] 🗺️ Handling map tap at screen location: \(location)")
        
        // Convert screen coordinates to map coordinates
        // This is a simplified approach - for production, consider using MapReader
        let mapRegion = locationManager.mapRegion
        
        // Calculate approximate coordinates based on tap position
        // This is a rough estimation based on screen dimensions
        let screenWidth: CGFloat = 400  // Approximate screen width
        let screenHeight: CGFloat = 400 // Approximate screen height
        
        // Calculate the offset from center (normalized to -0.5 to 0.5)
        let xOffset = (location.x - screenWidth / 2) / screenWidth
        let yOffset = (location.y - screenHeight / 2) / screenHeight
        
        // Convert to latitude/longitude offset
        let latOffset = yOffset * mapRegion.span.latitudeDelta
        let lonOffset = xOffset * mapRegion.span.longitudeDelta
        
        // Calculate final coordinates
        let tapLatitude = mapRegion.center.latitude - latOffset
        let tapLongitude = mapRegion.center.longitude + lonOffset
        
        let tappedCoordinate = CLLocationCoordinate2D(latitude: tapLatitude, longitude: tapLongitude)
        
        debugPrint("[RatingsMapView] 📍 Converted to map coordinates: \(tappedCoordinate.latitude), \(tappedCoordinate.longitude)")
        
        // Create FoodLocation from tapped coordinates
        let tappedLocation = FoodLocation(latitude: tappedCoordinate.latitude, longitude: tappedCoordinate.longitude)
        
        // Open AddRatingView with the tapped location
        activeSheet = .addRatingAtLocation(tappedLocation, name: nil)
        
        debugPrint("[RatingsMapView] ✅ Opening AddRatingView for tapped location")
    }
}

// #Preview {
//     let demoRating: FoodRating = FoodRating(
//         userId: UUID(), // Demo user ID
//         foodImageData: UIImage(systemName: "takeoutbag.and.cup.and.straw")!.pngData()!,
//         cartImageData: nil,
//         rating: 7,
//         notes: "Nice noodles",
//         displayName: "Noodle Cart",
//         location: FoodLocation(latitude: 13.7563, longitude: 100.5018)
//     )
//     let vm = RatingsViewModel()
//     vm.ratings = [demoRating]
//     RatingsMapView(model: vm)
// }

// MARK: - Helper Types

/// Keeps track of which sheet the map is showing.
private enum ActiveSheet: Identifiable {
    case addRating
    case addRatingAtLocation(FoodLocation, name: String?)

    var id: Int {
        switch self {
        case .addRating:
            return 0
        case .addRatingAtLocation:
            return 1
        }
    }
}

