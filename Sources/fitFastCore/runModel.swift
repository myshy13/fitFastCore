//
//  runModel.swift
//  fitFastCore
//
//  Created by Hamish Mcintyre on 2/3/2026.
//

import Foundation

public struct Run: Identifiable, Decodable {
    public let id: Int
    public let userID: Int
    public let name: String
    public let description: String?
    public let timestamp: String
    public let distance: Double
    public let minutes: Int
    public let seconds: Int

    // Converts the ISO8601 string (with fractional seconds) to a Date
    public var date: Date {
        guard let parsed = Self.isoFormatter.date(from: timestamp) else {
            fatalError("Invalid ISO8601 date string: \(timestamp)")
        }
        return parsed
    }

    private static var isoFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case userID = "userId"   // map JSON userId -> userID
        case name
        case description
        case timestamp
        case distance
        case minutes
        case seconds
    }
}
