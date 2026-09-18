import Foundation
import SwiftUI

enum IssueCategory: String, CaseIterable, Identifiable, Codable, Equatable {
    case unavailable
    case dirty
    case damaged
    case wrongLocation
    case closed
    case other

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .unavailable:
            "無法使用"
        case .dirty:
            "環境髒亂"
        case .damaged:
            "設備損壞"
        case .wrongLocation:
            "位置錯誤"
        case .closed:
            "未開放"
        case .other:
            "其他問題"
        }
    }

    var symbolName: String {
        switch self {
        case .unavailable:
            "xmark.circle"
        case .dirty:
            "sparkles"
        case .damaged:
            "wrench.and.screwdriver"
        case .wrongLocation:
            "mappin.slash"
        case .closed:
            "lock"
        case .other:
            "ellipsis.circle"
        }
    }
}

struct IssueReport: Identifiable, Codable, Equatable {
    let id: UUID
    let facilityID: Facility.ID
    let facilityName: String
    let category: IssueCategory
    let detail: String
    let contact: String
    let createdAt: Date
}
