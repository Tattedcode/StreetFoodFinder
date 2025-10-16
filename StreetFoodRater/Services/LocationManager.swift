//
//  LocationManager.swift
//  StreetFoodRater
//
//  Created by GPT on 16/10/2025.
//
//  Kid-Friendly Explanation:
//  This is like the GPS in your car!
//  It asks your phone: "Where am I right now?"
//  Then uses that location to:
//  - Center the map on YOU
//  - Automatically set the location when rating food
//  Think of it like using "Current Location" in Google Maps!
//

import Foundation
import CoreLocation
import MapKit

/// Manages device location (GPS)
@MainActor
@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    
    /// The actual iOS location manager
    private let manager = CLLocationManager()
    
    /// User's current location (nil if not available yet)
    var currentLocation: CLLocationCoordinate2D?
    
    /// Is location permission granted?
    var isAuthorized = false
    
    /// Current map region (updates when location changes)
    var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 14.5995, longitude: 120.9842), // Manila, Philippines default
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        debugPrint("[LocationManager] Initialized")
    }
    
    /// Request location permission from user
    func requestPermission() {
        debugPrint("[LocationManager] Requesting location permission...")
        manager.requestWhenInUseAuthorization()
    }
    
    /// Start tracking user's location
    func startTracking() {
        debugPrint("[LocationManager] Starting location tracking...")
        manager.startUpdatingLocation()
    }
    
    /// Stop tracking (saves battery)
    func stopTracking() {
        debugPrint("[LocationManager] Stopping location tracking...")
        manager.stopUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                debugPrint("[LocationManager] ✅ Location permission granted!")
                isAuthorized = true
                startTracking()
                
            case .denied, .restricted:
                debugPrint("[LocationManager] ❌ Location permission denied")
                isAuthorized = false
                
            case .notDetermined:
                debugPrint("[LocationManager] ⏳ Location permission not determined yet")
                
            @unknown default:
                break
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            
            let coordinate = location.coordinate
            debugPrint("[LocationManager] 📍 Location updated: \(coordinate.latitude), \(coordinate.longitude)")
            
            currentLocation = coordinate
            
            // Update map region to center on user's location
            mapRegion = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        debugPrint("[LocationManager] ❌ Location error: \(error.localizedDescription)")
    }
}

