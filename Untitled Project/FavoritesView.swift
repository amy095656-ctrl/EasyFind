import CoreLocation
import SwiftUI

struct FavoritesView: View {
    @Bindable var viewModel: FacilityViewModel
    let locationManager: LocationManager
    let onNavigateToFacility: (Facility) -> Void
    let onNavigateToReport: (Facility) -> Void

    @State private var selectedFilter: FacilityFilter = .all
    @State private var searchText = ""

    private var favoritedFacilities: [Facility] {
        let userLoc = locationManager.userLocation
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        let list = viewModel.facilities.filter { facility in
            guard viewModel.isFavorite(facility.id) else { return false }
            guard facilityMatchesFilter(facility, filter: selectedFilter) else { return false }

            if query.isEmpty { return true }
            return facility.name.localizedCaseInsensitiveContains(query) ||
                   facility.address.localizedCaseInsensitiveContains(query) ||
                   (facility.detailedLocation?.localizedCaseInsensitiveContains(query) ?? false) ||
                   facility.city.localizedCaseInsensitiveContains(query) ||
                   facility.district.localizedCaseInsensitiveContains(query)
        }

        return list.sorted { lhs, rhs in
            guard let userLoc else {
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
            return userLoc.distance(from: lhs.location) < userLoc.distance(from: rhs.location)
        }
    }

    private func facilityMatchesFilter(_ facility: Facility, filter: FacilityFilter) -> Bool {
        switch filter {
        case .all:
            return true
        case .drinkingWater:
            return facility.type == .drinkingWater
        case .restroom:
            return facility.type == .restroom
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Picker Header
                VStack(spacing: 8) {
                    Picker("設施類型", selection: $selectedFilter) {
                        ForEach(FacilityFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGroupedBackground))

                Divider()

                Group {
                    if favoritedFacilities.isEmpty {
                        ContentUnavailableView(
                            selectedFilter == .all && searchText.isEmpty ? "尚無收藏的設施" : "找不到符合條件的收藏設施",
                            systemImage: "heart.slash",
                            description: Text(selectedFilter == .all && searchText.isEmpty ? "在地圖或搜尋詳情卡片中點擊 ❤️ 即可新增收藏。" : "請嘗試切換篩選分類或清除搜尋關鍵字。")
                        )
                    } else {
                        List {
                            ForEach(favoritedFacilities) { facility in
                                FavoriteRowView(
                                    facility: facility,
                                    distanceText: facility.distanceText(from: locationManager.userLocation),
                                    isFavorite: viewModel.isFavorite(facility.id),
                                    onToggleFavorite: {
                                        viewModel.toggleFavorite(facility.id)
                                    },
                                    onSelectFacility: {
                                        onNavigateToFacility(facility)
                                    },
                                    onReport: {
                                        onNavigateToReport(facility)
                                    }
                                )
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                }
            }
            .navigationTitle("我的收藏")
            .searchable(text: $searchText, prompt: "搜尋收藏的設施名稱或地址")
        }
    }
}

struct FavoriteRowView: View {
    let facility: Facility
    let distanceText: String
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    let onSelectFacility: () -> Void
    let onReport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(facility.type.tint.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: facility.type.symbolName)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(facility.type.tint)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(facility.type.title)
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .foregroundStyle(facility.type.tint)
                            .background(facility.type.tint.opacity(0.12), in: Capsule())

                        Text(distanceText)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Text(facility.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }

                Spacer()

                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundStyle(isFavorite ? .red : .gray)
                        .padding(6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isFavorite ? "取消收藏" : "加入收藏")
            }

            Text(facility.address)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let detailedLocation = facility.detailedLocation {
                HStack(spacing: 4) {
                    Image(systemName: "location.north.line.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(detailedLocation)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                Button(action: onSelectFacility) {
                    Label("在地圖檢視", systemImage: "map.fill")
                        .font(.footnote.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)

                Button(action: onReport) {
                    Label("回報問題", systemImage: "exclamationmark.bubble")
                        .font(.footnote.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    FavoritesView(
        viewModel: FacilityViewModel(),
        locationManager: LocationManager(),
        onNavigateToFacility: { _ in },
        onNavigateToReport: { _ in }
    )
}
