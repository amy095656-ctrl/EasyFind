import CoreLocation
import Foundation
import MapKit
import SwiftUI

enum FacilityType: String, CaseIterable, Codable, Equatable, Identifiable {
    case drinkingWater
    case restroom

    var id: Self { self }

    var title: String {
        switch self {
        case .drinkingWater:
            "飲水機"
        case .restroom:
            "廁所"
        }
    }

    var symbolName: String {
        switch self {
        case .drinkingWater:
            "drop.fill"
        case .restroom:
            "figure.dress.line.vertical.figure"
        }
    }

    var tint: Color {
        switch self {
        case .drinkingWater:
            .cyan
        case .restroom:
            .green
        }
    }
}

enum WaterTemperature: String, CaseIterable, Codable, Equatable, Identifiable {
    case cold
    case warm
    case hot

    var id: Self { self }

    var title: String {
        switch self {
        case .cold:
            "冰水"
        case .warm:
            "溫水"
        case .hot:
            "熱水"
        }
    }

    var symbolName: String {
        switch self {
        case .cold:
            "snowflake"
        case .warm:
            "drop.fill"
        case .hot:
            "flame.fill"
        }
    }

    var tint: Color {
        switch self {
        case .cold:
            .blue
        case .warm:
            .cyan
        case .hot:
            .orange
        }
    }
}

enum FeatureCategory: String, CaseIterable, Identifiable {
    case drinkingWater = "飲水機條件"
    case restroom = "廁所條件"
    case general = "通用與開放條件"

    var id: Self { self }
}

enum FacilityFeature: String, CaseIterable, Codable, Equatable, Identifiable {
    // 飲水機條件
    case hasColdWater
    case hasWarmWater
    case hasHotWater

    // 廁所條件
    case accessible
    case familyFriendly
    case genderInclusive

    // 通用條件
    case openAllDay
    case indoor
    case outdoor
    case comboFacility

    var id: Self { self }

    var category: FeatureCategory {
        switch self {
        case .hasColdWater, .hasWarmWater, .hasHotWater:
            return .drinkingWater
        case .accessible, .familyFriendly, .genderInclusive:
            return .restroom
        case .openAllDay, .indoor, .outdoor, .comboFacility:
            return .general
        }
    }

    var title: String {
        switch self {
        case .hasColdWater:
            "提供冰水"
        case .hasWarmWater:
            "提供溫水"
        case .hasHotWater:
            "提供熱水"
        case .accessible:
            "無障礙設施"
        case .familyFriendly:
            "親子/尿布台"
        case .genderInclusive:
            "性別友善"
        case .openAllDay:
            "24 小時開放"
        case .indoor:
            "室內場域"
        case .outdoor:
            "室外場域"
        case .comboFacility:
            "同地點水廁"
        }
    }

    var symbolName: String {
        switch self {
        case .hasColdWater:
            "snowflake"
        case .hasWarmWater:
            "drop.fill"
        case .hasHotWater:
            "flame.fill"
        case .accessible:
            "figure.roll"
        case .familyFriendly:
            "figure.and.child.holdinghands"
        case .genderInclusive:
            "person.2"
        case .openAllDay:
            "clock"
        case .indoor:
            "building.2"
        case .outdoor:
            "tree"
        case .comboFacility:
            "hand.tap.fill"
        }
    }
}

struct Facility: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let name: String
    let type: FacilityType
    let latitude: Double
    let longitude: Double
    let address: String
    let detailedLocation: String?
    let waterTemperatures: [WaterTemperature]?
    let openingHours: String?
    let features: [FacilityFeature]
    let sourceName: String
    let lastUpdated: String

    var computedFeatures: Set<FacilityFeature> {
        var set = Set(features)
        if type == .drinkingWater, let temps = waterTemperatures {
            if temps.contains(.cold) { set.insert(.hasColdWater) }
            if temps.contains(.warm) { set.insert(.hasWarmWater) }
            if temps.contains(.hot) { set.insert(.hasHotWater) }
        }
        return set
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    var mapItem: MKMapItem {
        let address = MKAddress(fullAddress: address, shortAddress: address)
        let item = MKMapItem(location: location, address: address)
        item.name = name
        return item
    }

    var city: String {
        let citySuffixes = ["市", "縣"]
        guard let endIndex = address.firstIndex(where: { character in
            citySuffixes.contains(String(character))
        }) else { return "其他" }

        return String(address[...endIndex])
    }

    var district: String {
        let remainder = address.dropFirst(city.count)
        guard let endIndex = remainder.firstIndex(where: { character in
            ["區", "鄉", "鎮", "市"].contains(String(character))
        }) else { return "未分類" }

        return String(remainder[...endIndex])
    }

    func distanceText(from userLocation: CLLocation?) -> String {
        guard let userLocation else { return "距離未知" }

        let distance = userLocation.distance(from: location)
        if distance >= 1000 {
            return String(format: "%.1f 公里", distance / 1000)
        }

        return "\(Int(distance.rounded())) 公尺"
    }
}

enum FacilityFilter: String, CaseIterable, Identifiable {
    case all
    case drinkingWater
    case restroom

    var id: Self { self }

    var title: String {
        switch self {
        case .all:
            "全部"
        case .drinkingWater:
            "飲水機"
        case .restroom:
            "廁所"
        }
    }

    var symbolName: String {
        switch self {
        case .all:
            "square.grid.2x2.fill"
        case .drinkingWater:
            "drop.fill"
        case .restroom:
            "figure.dress.line.vertical.figure"
        }
    }

    func includes(_ type: FacilityType) -> Bool {
        switch self {
        case .all:
            true
        case .drinkingWater:
            type == .drinkingWater
        case .restroom:
            type == .restroom
        }
    }
}
