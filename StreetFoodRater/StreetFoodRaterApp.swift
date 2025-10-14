//
//  StreetFoodRaterApp.swift
//  StreetFoodRater
//
//  Created by Liam Brown on 14/10/2568 BE.
//

import SwiftUI

@main
struct StreetFoodRaterApp: App {
    /// We create one shared view model for the whole app so every screen can talk to the same brain.
    private let ratingsViewModel = RatingsViewModel()

    var body: some Scene {
        WindowGroup {
            RatingsMapView(model: ratingsViewModel)
        }
    }
}
