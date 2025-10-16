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

struct MainTabView: View {
    /// The shared brain for all ratings
    let model: RatingsViewModel
    
    /// Tracks which tab is currently selected
    @State private var selectedTab: Tab = .map
    
    /// Controls whether the add rating sheet is shown
    @State private var showAddRating = false
    
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
                
                // List Tab
                RatingsListView(model: model)
                    .tabItem {
                        Label("List", systemImage: "list.bullet")
                    }
                    .tag(Tab.list)
            }
            .tint(.purple)  // Purple selected color to match your theme
            
            // Floating Add Button (middle of tab bar)
            Button {
                debugPrint("[MainTabView] Add button tapped")
                showAddRating = true
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
        .sheet(isPresented: $showAddRating) {
            AddRatingView(model: model)
        }
        .onAppear {
            debugPrint("[MainTabView] Appeared with initial tab: \(selectedTab)")
        }
    }
    
    /// Enum to track which tab is selected
    enum Tab {
        case map
        case search
        case add  // Middle placeholder
        case favorites
        case list
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

/// Placeholder profile view for future features
private struct ProfileView: View {
    let model: RatingsViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.purple)
                
                Text("Profile")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.purple)
                
                Text("Coming soon!")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.secondary)
                
                // Stats section
                VStack(spacing: 12) {
                    StatRow(title: "Total Ratings", value: "\(model.ratings.count)")
                    
                    if !model.ratings.isEmpty {
                        let avgRating = Double(model.ratings.map { $0.rating }.reduce(0, +)) / Double(model.ratings.count)
                        StatRow(title: "Average Rating", value: String(format: "%.1f ⭐", avgRating))
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

/// Simple stat row for profile
private struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundStyle(Color.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.purple)
        }
    }
}

#Preview {
    MainTabView(model: RatingsViewModel())
}

