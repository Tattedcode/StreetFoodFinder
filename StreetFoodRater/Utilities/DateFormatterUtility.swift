//
//  DateFormatterUtility.swift
//  StreetFoodRater
//
//  Created by GPT on 14/10/2025.
//
//  Kid-Friendly Explanation:
//  This helper turns a `Date` (like 2025-10-14 10:33:00) into a friendly string we can read (like "Oct 14, 2025").
//

import Foundation

enum DateFormatterUtility {
    /// Shared formatter so we don't rebuild it every time (formatters are expensive to make).
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    /// Converts a `Date` into a nice string like "Oct 14, 2025 at 10:33 AM".
    static func string(from date: Date) -> String {
        let output = formatter.string(from: date)
        debugPrint("[DateFormatterUtility] Converted Date -> String: \(output)")
        return output
    }
}


