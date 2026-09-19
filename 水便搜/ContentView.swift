import CoreLocation
import MapKit
import SwiftUI

struct ContentView: View {
    @State private var viewModel = FacilityViewModel()
    @State private var selectedTab: AppTab = .map
    @State private var reportSubTab: ReportSubTab = .submit
    @State private var locationManager = LocationManager()

    var body: some View {
        TabView(selection: $selectedTab) {
            MapSearchView(
                viewModel: viewModel,
                locationManager: locationManager,
                onNavigateToReport: { facility in
                    SoundManager.shared.stopSound()
                    viewModel.selectedFacilityID = facility.id
                    viewModel.selectedCity = facility.city
                    viewModel.selectedDistrict = facility.district
                    reportSubTab = .submit
                    selectedTab = .report
                }
            )
            .tabItem {
                Label("地圖", systemImage: "map.fill")
            }
            .tag(AppTab.map)

            FavoritesView(
                viewModel: viewModel,
                locationManager: locationManager,
                onNavigateToFacility: { facility in
                    SoundManager.shared.stopSound()
                    viewModel.selectedFacilityID = facility.id
                    selectedTab = .map
                },
                onNavigateToReport: { facility in
                    SoundManager.shared.stopSound()
                    viewModel.selectedFacilityID = facility.id
                    viewModel.selectedCity = facility.city
                    viewModel.selectedDistrict = facility.district
                    reportSubTab = .submit
                    selectedTab = .report
                }
            )
            .tabItem {
                Label("我的收藏", systemImage: "heart.fill")
            }
            .tag(AppTab.favorites)

            ReportIssueView(
                viewModel: viewModel,
                selectedSubTab: $reportSubTab,
                onSelectFacilityOnMap: { facility in
                    SoundManager.shared.stopSound()
                    viewModel.selectedFacilityID = facility.id
                    selectedTab = .map
                }
            )
            .tabItem {
                Label("回報", systemImage: "exclamationmark.bubble.fill")
            }
            .tag(AppTab.report)
        }
        .task {
            await viewModel.loadFacilities()
        }
    }
}

private enum AppTab: Hashable {
    case map
    case favorites
    case report
}

struct MapSearchView: View {
    @Bindable var viewModel: FacilityViewModel
    let locationManager: LocationManager
    let onNavigateToReport: (Facility) -> Void
    @State private var cameraPosition: MapCameraPosition = .region(.taiwanOverview)
    @State private var mapCenter = CLLocationCoordinate2D(latitude: 23.8, longitude: 121.0)
    @State private var mapDistance: CLLocationDistance = 500_000
    @State private var isShowingAdvancedFilters = false
    @State private var isLocatingUser = false
    @Namespace private var mapScope

    var body: some View {
        ZStack(alignment: .top) {
            FacilityMapView(
                facilities: viewModel.visibleFacilities(userLocation: locationManager.userLocation),
                selectedFacilityID: $viewModel.selectedFacilityID,
                cameraPosition: $cameraPosition,
                mapScope: mapScope,
                onCameraChange: { center, distance in
                    mapCenter = center
                    mapDistance = distance
                }
            )
            .ignoresSafeArea()

            VStack(spacing: 8) {
                SearchHeaderView(
                    searchText: $viewModel.searchText,
                    message: viewModel.message ?? locationManager.locationError,
                    isLoading: viewModel.isLoading,
                    suggestions: viewModel.searchSuggestions(userLocation: locationManager.userLocation),
                    userLocation: locationManager.userLocation,
                    onSearch: performSearch,
                    onLocate: focusUserLocation,
                    onSelectSuggestion: { facility in
                        viewModel.selectedFacilityID = facility.id
                    }
                )

                FilterBarView(
                    selectedFilter: $viewModel.selectedFilter,
                    hasAdvancedFilters: viewModel.hasAdvancedFilters,
                    onOpenAdvancedFilters: {
                        viewModel.selectedFacilityID = nil
                        SoundManager.shared.stopSound()
                        isShowingAdvancedFilters = true
                    }
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Floating control buttons (Zoom + / Zoom -)
            VStack {
                Spacer()

                HStack {
                    Spacer()

                    VStack(spacing: 8) {
                        Button {
                            zoomIn()
                        } label: {
                            Image(systemName: "plus")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.primary)
                                .frame(width: 44, height: 44)
                                .background(.regularMaterial, in: Circle())
                                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("放大地圖")

                        Button {
                            zoomOut()
                        } label: {
                            Image(systemName: "minus")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.primary)
                                .frame(width: 44, height: 44)
                                .background(.regularMaterial, in: Circle())
                                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("縮小地圖")
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, (viewModel.selectedFacility != nil) ? 10 : 30)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let selectedFacility = viewModel.selectedFacility {
                FacilityResultsPanel(
                    selectedFacility: selectedFacility,
                    userLocation: locationManager.userLocation,
                    isFavorite: viewModel.isFavorite(selectedFacility.id),
                    liveNews: viewModel.liveNews(for: selectedFacility.id),
                    onToggleFavorite: {
                        viewModel.toggleFavorite(selectedFacility.id)
                    },
                    onOpenAppleMaps: openAppleMaps,
                    onOpenGoogleMaps: openGoogleMaps,
                    onReport: { facility in
                        SoundManager.shared.stopSound()
                        onNavigateToReport(facility)
                    },
                    onDismissDetail: {
                        SoundManager.shared.stopSound()
                        viewModel.selectedFacilityID = nil
                    }
                )
            }
        }
        .sheet(isPresented: $isShowingAdvancedFilters) {
            AdvancedFilterView(viewModel: viewModel)
        }
        .mapScope(mapScope)
        .onAppear {
            locationManager.requestLocation()
        }
        .onChange(of: locationManager.userLocation) { _, newLocation in
            if isLocatingUser, let newLocation {
                focus(newLocation.coordinate, distance: 900)
                isLocatingUser = false
            }
        }
        .onChange(of: viewModel.selectedFilter) { _, _ in
            viewModel.selectedFacilityID = nil
            SoundManager.shared.stopSound()
        }
        .onChange(of: viewModel.selectedFacilityID) { _, newValue in
            if let newValue,
               let facility = viewModel.facilities.first(where: { $0.id == newValue }) {
                focus(facility.coordinate, distance: 850)

                switch facility.type {
                case .drinkingWater:
                    SoundManager.shared.playWaterSound()
                case .restroom:
                    SoundManager.shared.playToiletSound()
                }
            } else {
                SoundManager.shared.stopSound()
            }
        }
    }

    private func performSearch() {
        Task {
            if let region = await viewModel.searchRegion() {
                withAnimation(.snappy) {
                    cameraPosition = .region(region)
                }
            }
        }
    }

    private func focusUserLocation() {
        isLocatingUser = true
        locationManager.requestLocation()

        if let userLocation = locationManager.userLocation {
            focus(userLocation.coordinate, distance: 900)
            isLocatingUser = false
        }
    }

    private func focus(_ coordinate: CLLocationCoordinate2D, distance: CLLocationDistance) {
        withAnimation(.snappy) {
            cameraPosition = .camera(
                MapCamera(centerCoordinate: coordinate, distance: distance, heading: 0, pitch: 0)
            )
        }
    }

    private func zoomIn() {
        let newDistance = max(mapDistance * 0.5, 100)
        mapDistance = newDistance
        withAnimation(.easeInOut(duration: 0.3)) {
            cameraPosition = .camera(
                MapCamera(centerCoordinate: mapCenter, distance: newDistance, heading: 0, pitch: 0)
            )
        }
    }

    private func zoomOut() {
        let newDistance = min(mapDistance * 2.0, 10_000_000)
        mapDistance = newDistance
        withAnimation(.easeInOut(duration: 0.3)) {
            cameraPosition = .camera(
                MapCamera(centerCoordinate: mapCenter, distance: newDistance, heading: 0, pitch: 0)
            )
        }
    }

    private func openAppleMaps(_ facility: Facility) {
        _ = facility.mapItem.openInMaps(
            launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking]
        )
    }

    private func openGoogleMaps(_ facility: Facility) {
        let lat = facility.latitude
        let lng = facility.longitude
        let schemeString = "comgooglemaps://?daddr=\(lat),\(lng)&directionsmode=walking"
        let webString = "https://www.google.com/maps/dir/?api=1&destination=\(lat),\(lng)&travelmode=walking"

        if let schemeURL = URL(string: schemeString), UIApplication.shared.canOpenURL(schemeURL) {
            UIApplication.shared.open(schemeURL)
        } else if let webURL = URL(string: webString) {
            UIApplication.shared.open(webURL)
        }
    }
}

struct FacilityMapView: View {
    let facilities: [Facility]
    @Binding var selectedFacilityID: Facility.ID?
    @Binding var cameraPosition: MapCameraPosition
    let mapScope: Namespace.ID
    let onCameraChange: (CLLocationCoordinate2D, CLLocationDistance) -> Void

    var body: some View {
        Map(position: $cameraPosition, selection: $selectedFacilityID, scope: mapScope) {
            UserAnnotation()

            ForEach(facilities) { facility in
                Marker(facility.name, systemImage: facility.type.symbolName, coordinate: facility.coordinate)
                    .tint(facility.type.tint)
                    .tag(facility.id)
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .mapControls {
            MapCompass(scope: mapScope)
            MapScaleView(scope: mapScope)
        }
        .onMapCameraChange(frequency: .continuous) { context in
            onCameraChange(context.camera.centerCoordinate, context.camera.distance)
        }
    }
}

struct SearchHeaderView: View {
    @Binding var searchText: String
    let message: String?
    let isLoading: Bool
    let suggestions: [Facility]
    let userLocation: CLLocation?
    let onSearch: () -> Void
    let onLocate: () -> Void
    let onSelectSuggestion: (Facility) -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("搜尋地點、地址或設施", text: $searchText)
                    .focused($isFocused)
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                    .onSubmit {
                        isFocused = false
                        onSearch()
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        onSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("清除搜尋")
                }

                Button(action: {
                    isFocused = false
                    onLocate()
                }) {
                    Image(systemName: "location.fill")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .accessibilityLabel("使用目前位置")
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))

            // Real-time Autocomplete / Search Suggestions Dropdown
            if isFocused && !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text("相關設施與地點")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                    Divider()

                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(suggestions.prefix(6)) { facility in
                                Button {
                                    isFocused = false
                                    searchText = facility.name
                                    onSelectSuggestion(facility)
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: facility.type.symbolName)
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(facility.type.tint)
                                            .frame(width: 24)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(facility.name)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.primary)

                                            Text("\(facility.city)\(facility.district) • \(facility.address)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }

                                        Spacer()

                                        Text(facility.distanceText(from: userLocation))
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)

                                    Divider()
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxHeight: 220)
                }
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.quaternary, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
            } else if isLoading {
                Label("正在載入附近設施", systemImage: "arrow.triangle.2.circlepath")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            } else if let message, !isFocused {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
        }
    }
}

struct FilterBarView: View {
    @Binding var selectedFilter: FacilityFilter
    let hasAdvancedFilters: Bool
    let onOpenAdvancedFilters: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Picker("設施類型", selection: $selectedFilter) {
                ForEach(FacilityFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            Button(action: onOpenAdvancedFilters) {
                HStack(spacing: 4) {
                    Image(systemName: "slider.horizontal.3")
                    Text("進階篩選")
                        .font(.footnote.weight(.semibold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .foregroundStyle(hasAdvancedFilters ? .white : .primary)
                .background(hasAdvancedFilters ? Color.accentColor : Color(.secondarySystemBackground), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

struct FacilityResultsPanel: View {
    let selectedFacility: Facility
    let userLocation: CLLocation?
    let isFavorite: Bool
    let liveNews: [LiveNewsItem]
    let onToggleFavorite: () -> Void
    let onOpenAppleMaps: (Facility) -> Void
    let onOpenGoogleMaps: (Facility) -> Void
    let onReport: (Facility) -> Void
    let onDismissDetail: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(.secondary.opacity(0.35))
                .frame(width: 38, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 6)

            FacilityDetailView(
                facility: selectedFacility,
                distanceText: selectedFacility.distanceText(from: userLocation),
                isFavorite: isFavorite,
                liveNews: liveNews,
                onToggleFavorite: onToggleFavorite,
                onOpenAppleMaps: { onOpenAppleMaps(selectedFacility) },
                onOpenGoogleMaps: { onOpenGoogleMaps(selectedFacility) },
                onReport: { onReport(selectedFacility) },
                onDismiss: onDismissDetail
            )
        }
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
    }
}

struct FacilityDetailView: View {
    let facility: Facility
    let distanceText: String
    let isFavorite: Bool
    let liveNews: [LiveNewsItem]
    let onToggleFavorite: () -> Void
    let onOpenAppleMaps: () -> Void
    let onOpenGoogleMaps: () -> Void
    let onReport: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header: Icon, Name, Distance & Favorite & Close buttons
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(facility.type.tint.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: facility.type.symbolName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(facility.type.tint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(facility.type.title)
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .foregroundStyle(facility.type.tint)
                            .background(facility.type.tint.opacity(0.12), in: Capsule())

                        Text(distanceText)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Text(facility.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }

                Spacer()

                HStack(spacing: 6) {
                    Button(action: onToggleFavorite) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.title3)
                            .foregroundStyle(isFavorite ? .red : .secondary)
                            .frame(width: 36, height: 36)
                            .background(Color(.tertiarySystemBackground), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isFavorite ? "取消收藏" : "加入收藏")

                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("關閉詳情")
                }
            }

            // Live News / User Report Status Notification Box (if available for this facility)
            if !liveNews.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        Text("即時維護與通報動態")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "bell.badge.fill")
                            .foregroundStyle(.orange)
                    }

                    ForEach(liveNews) { news in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(news.status.title)
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .foregroundStyle(news.status.color)
                                    .background(news.status.color.opacity(0.15), in: Capsule())

                                Text(news.timeText)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }

                            Text(news.title)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.primary)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(news.status.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                .padding(10)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            // Location Box Card
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(facility.type.tint)
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(facility.address)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        if let detailedLocation = facility.detailedLocation {
                            HStack(spacing: 4) {
                                Image(systemName: "location.north.line.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(detailedLocation)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 2)
                        }
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Drinking Water Temperature Section (if applicable)
            if facility.type == .drinkingWater, let temps = facility.waterTemperatures, !temps.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Label {
                        Text("提供水溫")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "thermometer.medium")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.accentColor)
                    }

                    HStack(spacing: 10) {
                        ForEach(temps) { temp in
                            HStack(spacing: 6) {
                                Image(systemName: temp.symbolName)
                                    .font(.subheadline)
                                Text(temp.title)
                                    .font(.subheadline.weight(.bold))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .foregroundStyle(temp.tint)
                            .background(temp.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(temp.tint.opacity(0.25), lineWidth: 1)
                            )
                        }
                    }
                }
            }

            // Info Grid: Opening Hours & Source
            HStack(spacing: 10) {
                // Opening Hours Card
                VStack(alignment: .leading, spacing: 4) {
                    Label("開放時間", systemImage: "clock.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(facility.openingHours ?? "未提供")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                // Source Card
                VStack(alignment: .leading, spacing: 4) {
                    Label("資料來源", systemImage: "checkmark.seal.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(facility.sourceName)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            // Feature Badges
            if !facility.features.isEmpty {
                FeaturePillsView(features: facility.features)
            }

            // Action Buttons
            HStack(spacing: 12) {
                Menu {
                    Button(action: onOpenAppleMaps) {
                        Label("Apple 地圖", systemImage: "map")
                    }

                    Button(action: onOpenGoogleMaps) {
                        Label("Google 地圖", systemImage: "globe")
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        Text("地圖導航")
                    }
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(.white)
                    .background(facility.type.tint, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: facility.type.tint.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(.plain)

                Button(action: onReport) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.bubble.fill")
                        Text("回報問題")
                    }
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(.primary)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.quaternary, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 2)
        }
        .padding(18)
    }
}

struct DetailLineView: View {
    let symbolName: String
    let text: String

    var body: some View {
        Label {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
        } icon: {
            Image(systemName: symbolName)
        }
    }
}

struct FeaturePillsView: View {
    let features: [FacilityFeature]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(features) { feature in
                    Label {
                        Text(feature.title)
                    } icon: {
                        Image(systemName: feature.symbolName)
                    }
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .foregroundStyle(.primary)
                    .background(Color(.tertiarySystemBackground), in: Capsule())
                    .overlay(
                        Capsule()
                            .stroke(.quaternary, lineWidth: 1)
                    )
                }
            }
        }
    }
}

private extension MKCoordinateRegion {
    static let taiwanOverview = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 23.8, longitude: 121.0),
        span: MKCoordinateSpan(latitudeDelta: 4.5, longitudeDelta: 3.2)
    )
}

#Preview {
    ContentView()
}
