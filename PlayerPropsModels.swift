//
//  PlayerPropsModels.swift
//  Multi-Sport Parlay Picker
//
//  Models for player props parlay builder
//

import Foundation
import SwiftUI // <--- CRITICAL FIX: Required for View, Identifiable, etc.

// MARK: - Stat Category

enum StatCategory: String, CaseIterable {
    case points
    case threes
    case assists
    case rebounds
    
    var displayName: String {
        switch self {
        case .points: return "Points"
        case .threes: return "3-Pointers"
        case .assists: return "Assists"
        case .rebounds: return "Rebounds"
        }
    }
    
    var suffix: String {
        switch self {
        case .points: return "p"
        case .threes: return "3"
        case .assists: return "a"
        case .rebounds: return "r"
        }
    }
}

// MARK: - Over/Under

enum OverUnder: String {
    case over = "O"
    case under = "U"
}

// MARK: - Player Prop Data

struct PlayerPropData: Identifiable {
    let id = UUID()
    let playerID: Int
    let fullName: String
    let abbreviation: String
    let pointsMedian: Double?
    let threesMedian: Double?
    let assistsMedian: Double?
    let reboundsMedian: Double?
    let gamesPlayed: Int
    
    // Properties for odds/probability
    let overOdds: Int?
    let underOdds: Int?
    let overProb: Double?
    let underProb: Double?
    
    func value(for category: StatCategory) -> Double? {
        switch category {
        case .points: return pointsMedian
        case .threes: return threesMedian
        case .assists: return assistsMedian
        case .rebounds: return reboundsMedian
        }
    }
    
    func medianValue(for category: StatCategory) -> String {
        guard let value = value(for: category) else { return "—" }
        return String(format: "%.1f", value)
    }
}

// MARK: - Selected Player Prop

struct SelectedPlayerProp: Identifiable, Equatable {
    let id = UUID()
    let playerID: Int
    let playerName: String
    let abbreviation: String
    let category: StatCategory
    let line: Double
    var overUnder: OverUnder
    
    // Properties for selection
    let probability: Double
    let odds: Int
    
    var shorthand: String {
        "\(abbreviation) \(overUnder.rawValue)\(String(format: "%.1f", line))\(category.suffix)"
    }
    
    // Custom logic to determine if two props are for the same player and category
    static func == (lhs: SelectedPlayerProp, rhs: SelectedPlayerProp) -> Bool {
        return lhs.playerID == rhs.playerID && lhs.category == rhs.category && lhs.overUnder == rhs.overUnder
    }
    
    // Helper to check for the same player and category, ignoring over/under
    func isSamePlayerAndCategory(as other: SelectedPlayerProp) -> Bool {
        return self.playerID == other.playerID && self.category == other.category
    }
}

// MARK: - Parlay Leg

struct ParlayLeg: Identifiable {
    let id = UUID()
    let playerID: Int
    let shorthand: String
    let category: StatCategory
    let line: Double
    let overUnder: OverUnder
    let probability: Double // 0.0 to 1.0
}

// MARK: - Generated Parlay

struct GeneratedParlay: Identifiable {
    let id: Int
    let legs: [ParlayLeg]
    let combinedProbability: Double
    
    var probabilityString: String {
        String(format: "%.1f%%", combinedProbability * 100)
    }
    
    var americanOdds: Int {
        if combinedProbability >= 0.5 {
            return Int(-100 * combinedProbability / (1 - combinedProbability))
        } else {
            return Int(100 * (1 - combinedProbability) / combinedProbability)
        }
    }
    
    var oddsString: String {
        let odds = americanOdds
        return odds > 0 ? "+\(odds)" : "\(odds)"
    }
}
// MARK: - Extensions

extension PlayerPropData {
    func overLine(for category: StatCategory) -> String {
        guard let value = value(for: category) else { return "—" }
        let line = value + 0.5
        return "O\(String(format: "%.1f", line))"
    }
    
    func underLine(for category: StatCategory) -> String {
        guard let value = value(for: category) else { return "—" }
        let line = value - 0.5
        return "U\(String(format: "%.1f", line))"
    }
}
