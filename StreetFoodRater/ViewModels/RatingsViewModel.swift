//
//  RatingsViewModel.swift
//  StreetFoodRater
//
//  Restored by GPT on 14/10/2025 after accidental deletion.
//
//  This is the "brain" (ViewModel) that stores all ratings, adds/removes them,
//  and saves/loads them from local storage so they persist across app launches.

import Foundation
import Observation

@Observable
@MainActor
final class RatingsViewModel {

    // All food rating cards
    var ratings: [FoodRating] = [] {
        didSet { debugPrint("[RatingsViewModel] Ratings changed. Total now: \(ratings.count)") }
    }

    private let backgroundQueue = DispatchQueue(label: "com.streetfoodrater.storage")
    private let storageURL: URL = {
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = folder.appendingPathComponent("ratings.json")
        debugPrint("[RatingsViewModel] Storage URL: \(url)")
        return url
    }()

    init() {
        debugPrint("[RatingsViewModel] Init")
    }

    func addRating(_ rating: FoodRating) {
        debugPrint("[RatingsViewModel] Adding rating: \(rating.id)")
        ratings.insert(rating, at: 0)
        scheduleSave()
    }

    func removeRating(by ratingID: UUID) {
        debugPrint("[RatingsViewModel] Removing rating: \(ratingID)")
        ratings.removeAll { $0.id == ratingID }
        scheduleSave()
    }

    func removeAllRatingsForDebug() {
        ratings.removeAll()
        scheduleSave()
    }

    private func scheduleSave() {
        let ratingsToSave = ratings
        backgroundQueue.async { [storageURL] in
            do {
                let data = try JSONEncoder().encode(ratingsToSave)
                try data.write(to: storageURL, options: .atomic)
                debugPrint("[RatingsViewModel] Saved ratings: \(ratingsToSave.count)")
            } catch {
                debugPrint("[RatingsViewModel] Save error: \(error)")
            }
        }
    }

    func loadFromStorageIfNeeded() {
        backgroundQueue.async { [weak self, storageURL] in
            do {
                let data = try Data(contentsOf: storageURL)
                let decoded = try JSONDecoder().decode([FoodRating].self, from: data)
                debugPrint("[RatingsViewModel] Loaded ratings: \(decoded.count)")
                Task { @MainActor in
                    self?.ratings = decoded
                }
            } catch {
                debugPrint("[RatingsViewModel] Load skipped or failed: \(error)")
            }
        }
    }
}



