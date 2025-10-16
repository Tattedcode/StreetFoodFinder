//
//  StreetFoodRaterApp.swift
//  StreetFoodRater
//
//  Created by Liam Brown on 14/10/2568 BE.
//
//  Kid-Friendly Explanation:
//  This is the "main entrance" to the app - the first thing that runs!
//  It checks: Are you logged in?
//  - YES → Show you the map and food ratings
//  - NO → Show you the login screen first
//  Think of it like a bouncer at a club checking if you have a membership card!
//

import SwiftUI

@main
struct StreetFoodRaterApp: App {
    /// Manages user authentication (who's logged in?)
    @State private var authViewModel = AuthViewModel()
    
    /// Manages all the food ratings data
    private let ratingsViewModel = RatingsViewModel()
    
    /// Manages user's GPS location
    @State private var locationManager = LocationManager()

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    // User is logged in → Show the main app
                    MainTabView(model: ratingsViewModel)
                        .environment(authViewModel)
                        .environment(locationManager)
                        .onAppear {
                            // Request location permission when app appears
                            locationManager.requestPermission()
                        }
                } else {
                    // User is NOT logged in → Show login screen
                    LoginView()
                        .environment(authViewModel)
                }
            }
        }
    }
}
