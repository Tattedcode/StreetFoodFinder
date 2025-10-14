//
//  ImageConverter.swift
//  StreetFoodRater
//
//  Created by GPT on 14/10/2025.
//
//  Kid-Friendly Explanation:
//  This helper takes the raw photo data (just a bunch of numbers) and turns it back
//  into a SwiftUI `Image` so we can show the picture of the food on the screen.
//

import SwiftUI
import UIKit

enum ImageConverter {
    /// Turns binary data (numbers) into a SwiftUI Image that we can show in the list.
    /// - Parameter data: The saved photo data from our `FoodRating` card.
    /// - Returns: A SwiftUI `Image` if the conversion worked, otherwise `nil`.
    static func makeImage(from data: Data) -> Image? {
        if let uiImage = UIImage(data: data) {
            debugPrint("[ImageConverter] Successfully turned Data into UIImage.")
            return Image(uiImage: uiImage)
        } else {
            debugPrint("[ImageConverter] FAILED to convert Data into UIImage. Showing placeholder.")
            return nil
        }
    }
}

