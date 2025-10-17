//
//  MainTabView.swift
//  StreetFoodRater
//
//  Created by GPT on 16/10/2025.
//
//  Kid-Friendly Explanation:
//  This is the main screen with tabs at the bottom so you can switch between
//  the map view and the list view. Like tabs in Safari!
//

import SwiftUI
import CoreLocation

struct MainTabView: View {
    /// The shared brain for all ratings
    let model: RatingsViewModel
    
    /// Tracks which tab is currently selected
    @State private var selectedTab: Tab = .map
    
    /// Controls whether the add rating sheet is shown
    @State private var showAddRating = false
    
    /// Controls whether the nearby cart selection is shown
    @State private var showNearbyCartSelection = false
    
    /// Location manager for getting current GPS
    @Environment(LocationManager.self) private var locationManager
    
    /// When user selects a cart, store it to prefill AddRatingView
    @State private var selectedCart: LocationGroup?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main TabView
            TabView(selection: $selectedTab) {
                // Map Tab
                RatingsMapView(model: model)
                    .tabItem {
                        Label("Map", systemImage: "map.fill")
                    }
                    .tag(Tab.map)
                
                // Search Tab (left of center)
                PlaceholderView(icon: "magnifyingglass", title: "Search", subtitle: "Coming Soon")
                    .tabItem {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    .tag(Tab.search)
                
                // Placeholder for middle (add button)
                Color.clear
                    .tabItem {
                        Label("", systemImage: "")
                    }
                    .tag(Tab.add)
                
                // Favorites Tab (right of center)
                PlaceholderView(icon: "heart.fill", title: "Favorites", subtitle: "Coming Soon")
                    .tabItem {
                        Label("Favorites", systemImage: "heart.fill")
                    }
                    .tag(Tab.favorites)
                
                // Profile Tab
                ProfileView(model: model)
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
                    .tag(Tab.profile)
            }
            .tint(.purple)  // Purple selected color to match your theme
            
            // Floating Add Button (middle of tab bar) - Only show on Map tab
            if selectedTab == .map {
                Button {
                    debugPrint("[MainTabView] Add button tapped")
                    checkForNearbyCarts()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(LinearGradient(colors: [Color.purple, Color.purple.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
                }
                .offset(y: -25)  // Lift it above the tab bar
            }
        }
        // Show nearby cart selection if there are carts nearby
        .sheet(isPresented: $showNearbyCartSelection) {
            if let userLocation = locationManager.currentLocation {
                NearbyCartSelectionView(
                    model: model,
                    userLocation: userLocation,
                    onCartSelected: { cart in
                        debugPrint("[MainTabView] User selected cart: \(cart.name)")
                        selectedCart = cart
                        showAddRating = true
                    },
                    onCreateNew: {
                        debugPrint("[MainTabView] User chose to create new cart")
                        selectedCart = nil
                        showAddRating = true
                    }
                )
            }
        }
        // Show add rating sheet
        .sheet(isPresented: $showAddRating) {
            if let cart = selectedCart,
               let firstRating = cart.latestRating {
                // Pre-fill with selected cart
                AddRatingView(
                    model: model,
                    prefilledLocation: firstRating.location,
                    prefilledName: cart.name
                )
            } else {
                // New cart
                AddRatingView(model: model)
            }
        }
        .onAppear {
            debugPrint("[MainTabView] Appeared with initial tab: \(selectedTab)")
        }
    }
    
    /// Check if there are any carts within 50 meters
    /// If yes → show selection screen
    /// If no → go directly to add rating
    private func checkForNearbyCarts() {
        guard let userLocation = locationManager.currentLocation else {
            debugPrint("[MainTabView] ⚠️ No GPS location available, opening add rating directly")
            selectedCart = nil
            showAddRating = true
            return
        }
        
        // Find carts within 50 meters
        let nearbyCarts = model.locationGroups.filter { group in
            let cartLocation = CLLocation(
                latitude: group.coordinate.latitude,
                longitude: group.coordinate.longitude
            )
            let userLoc = CLLocation(
                latitude: userLocation.latitude,
                longitude: userLocation.longitude
            )
            return userLoc.distance(from: cartLocation) <= 50
        }
        
        if nearbyCarts.isEmpty {
            debugPrint("[MainTabView] No carts nearby, opening add rating directly")
            selectedCart = nil
            showAddRating = true
        } else {
            debugPrint("[MainTabView] Found \(nearbyCarts.count) nearby carts, showing selection")
            showNearbyCartSelection = true
        }
    }
    
    /// Enum to track which tab is selected
    enum Tab {
        case map
        case search
        case add  // Middle placeholder
        case favorites
        case profile
    }
}

/// Generic placeholder view for tabs coming soon
private struct PlaceholderView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: icon)
                    .font(.system(size: 80))
                    .foregroundStyle(Color.purple)
                
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.purple)
                
                Text(subtitle)
                    .font(.system(size: 18))
                    .foregroundStyle(Color.secondary)
                
                Text("This feature is under development")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.secondary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


#Preview {
    MainTabView(model: RatingsViewModel())
}

