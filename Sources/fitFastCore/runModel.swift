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
    public let description: String
    public let timestamp: String
    public let distance: Double
    public let minutes: Int
    public let seconds: Int

    /// Converts the ISO8601 string to a Date
    public var date: Date {
        guard let parsed = Self.isoFormatter.date(from: timestamp) else {
            fatalError("Invalid ISO8601 date string: \(timestamp)")
        }
        return parsed
    }

    // Concurrency-safe computed formatter
    private static var isoFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }

    private enum CodingKeys: String, CodingKey {
        case id, userID, name, description, timestamp, distance, minutes, seconds
    }

    public init(
        id: Int,
        userID: Int,
        name: String,
        description: String?,
        timestamp: String,
        distance: Double,
        minutes: Int,
        seconds: Int
    ) {
        self.id = id
        self.userID = userID
        self.name = name
        self.description = description ?? ""
        self.timestamp = timestamp
        self.distance = distance
        self.minutes = minutes
        self.seconds = seconds
    }
}
