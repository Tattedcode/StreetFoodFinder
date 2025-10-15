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
    /// Helps us decide which sheet (if any) is currently open.
    @State private var activeSheet: ActiveSheet?
    /// Remembers which popular food tag is currently highlighted.
    @State private var selectedPopularFoodIndex: Int = 0
    /// Text user types in the floating search field.
    @State private var searchText: String = ""

    /// The default region centers on Bangkok to start the map somewhere familiar.
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 13.7563, longitude: 100.5018),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

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
            }
        }
        .onAppear {
            debugPrint("[RatingsMapView] Appeared -> requesting model to load ratings.")
            model.loadFromStorageIfNeeded()
        }
    }

    /// The map with markers for each rating.
    private var mapContent: some View {
        Map(initialPosition: .region(mapRegion)) {
            ForEach(model.ratings) { rating in
                Marker(
                    rating.displayName ?? "Yummy Cart",
                    coordinate: rating.location.coordinate
                )
                .tint(.orange)
                .tag(rating.id)
            }
        }
        .mapControls {
            MapCompass()
        }
        .mapStyle(.standard(elevation: .realistic))
    }

    /// Combines the top header (full-width background up to top) and the bottom bar.
    private var overlayUI: some View {
        VStack(spacing: 0) {
            topHeaderArea
            topFilterChips
                .padding(.horizontal, 12)
                .padding(.top, 14)
            Spacer()
            bottomPreviewPanel
        }
        .padding(.horizontal, 0)
//        .padding(.top, -28)
    }

    /// Full-width header background that reaches the top; search stays in place.
    private var topHeaderArea: some View {
        VStack(spacing: 6) {
            Text("Street Food Finder")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.blue)

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

    /// Horizontal row of purple pill buttons that show popular food tags.
    private var topFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(popularFoodNames.enumerated()), id: \.offset) { item in
                    let (index, name) = item
                    Button {
                        debugPrint("[RatingsMapView] Popular food tag tapped: \(name)")
                        selectedPopularFoodIndex = index
                    } label: {
                        Text(name)
                            .font(.system(size: 16, weight: .semibold))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(popularFoodGradient(for: index))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
                            )
                            .clipShape(Capsule())
                            .foregroundStyle(index == selectedPopularFoodIndex ? Color.white : Color.purple)
                            .shadow(color: Color.purple.opacity(0.25), radius: 6, x: 0, y: 3)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    /// Bottom bar: full width, touches the bottom of the screen.
    private var bottomPreviewPanel: some View {
        VStack(spacing: 12) {
            Capsule()
                .fill(Color.white.opacity(0.4))
                .frame(width: 46, height: 5)

            Button {
                debugPrint("[RatingsMapView] Nearby button tapped - presenting nearby picker sheet.")
                activeSheet = .nearby
            } label: {
                HStack(spacing: 8) {
                    Text("Most Nearby")
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 12, weight: .bold))
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.purple)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Color.white)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.top, 12)
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .background(
            TopRoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.92))
                .shadow(color: Color.black.opacity(0.12), radius: 14, x: 0, y: 8)
                .padding(.bottom, -48)
        )
        .ignoresSafeArea(edges: .bottom)
    }

    /// Gives each chip a bright purple gradient when selected, and a pale one otherwise.
    private func popularFoodGradient(for index: Int) -> LinearGradient {
        let colors = index == selectedPopularFoodIndex ? [Color.purple, Color.purple.opacity(0.7)] : [Color.white.opacity(0.85), Color.white.opacity(0.6)]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var popularFoodNames: [String] {
        ["Food 1", "Food 2", "Food 3", "Food 4", "Food 5", "Food 6"]
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
            NearbyFoodOption(name: "Pad Thai at Soi 7", distance: "120m away"),
            NearbyFoodOption(name: "Grilled Satay Cart", distance: "220m away"),
            NearbyFoodOption(name: "Mango Sticky Rice Stand", distance: "340m away"),
            NearbyFoodOption(name: "Tom Yum Boat", distance: "500m away")
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

    var id: Int {
        switch self {
        case .addRating:
            return 0
        case .nearby:
            return 1
        }
    }
}

/// Dummy row information for the nearby picker.
private struct NearbyFoodOption: Identifiable {
    let id = UUID()
    let name: String
    let distance: String
}

/// Sheet that shows pretend nearby food results.
private struct NearbyPickerSheet: View {
    /// Pretend options that the user can pick.
    let options: [NearbyFoodOption]
    /// Called when the kid taps one of the rows.
    let onSelect: (NearbyFoodOption) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(options) { option in
                Button {
                    debugPrint("[NearbyPickerSheet] User tapped \(option.name)")
                    onSelect(option)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(option.name)
                                .font(.system(size: 17, weight: .semibold))
                            Text(option.distance)
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Color.purple)
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("Choose Nearby Food")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        debugPrint("[NearbyPickerSheet] Done tapped.")
                        dismiss()
                    }
                }
            }
        }
    }
}
