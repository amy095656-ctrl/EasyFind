import CoreLocation
import Foundation
import MapKit
import Observation

@MainActor
@Observable
final class FacilityViewModel {
    private let repository = FacilityRepository()
    private(set) var facilities: [Facility] = []
    private(set) var searchedCoordinate: CLLocationCoordinate2D?
    var searchText = ""
    var selectedFilter: FacilityFilter = .all
    var requiredFeatures: Set<FacilityFeature> = []
    var selectedCity: String?
    var selectedDistrict: String?
    var selectedFacilityID: Facility.ID?
    var isLoading = false
    var message: String?
    private(set) var issueReports: [IssueReport] = []
    private(set) var liveNewsItems: [LiveNewsItem] = [
        LiveNewsItem(
            id: "news-1",
            facilityID: "water-tpe-main-station",
            status: .inProgress,
            facilityName: "台北車站公共飲水點",
            locationText: "台北市中正區",
            title: "飲水機濾芯例行更換與水質品質檢測中",
            timeText: "今日 10:30",
            createdAt: Date()
        ),
        LiveNewsItem(
            id: "news-2",
            facilityID: "toilet-da-an-park",
            status: .fixed,
            facilityName: "大安森林公園公廁",
            locationText: "台北市大安區",
            title: "2號無障礙廁所門鎖故障已完成修復作業",
            timeText: "今日 08:15",
            createdAt: Date()
        ),
        LiveNewsItem(
            id: "news-3",
            facilityID: "water-banqiao-station",
            status: .reported,
            facilityName: "板橋車站飲水機",
            locationText: "新北市板橋區",
            title: "溫水燈號閃爍通報，原廠維修技師派員前往中",
            timeText: "昨日 16:40",
            createdAt: Date()
        ),
        LiveNewsItem(
            id: "news-4",
            facilityID: "D270000154",
            status: .cleaned,
            facilityName: "奇美博物館女廁",
            locationText: "臺南市仁德區",
            title: "全館洗洗間例行高規格消毒與環境深層保養完畢",
            timeText: "昨日 12:00",
            createdAt: Date()
        ),
        LiveNewsItem(
            id: "news-5",
            facilityID: "F060000141",
            status: .fixed,
            facilityName: "捷運大坪林站女廁",
            locationText: "新北市新店區",
            title: "感應式水頭感應模組更換完畢，恢復正常水壓",
            timeText: "前日 14:20",
            createdAt: Date()
        ),
        LiveNewsItem(
            id: "news-6",
            facilityID: "G050000019",
            status: .inProgress,
            facilityName: "湯圍溝公園無障礙廁所",
            locationText: "宜蘭縣礁溪鄉",
            title: "周邊地管防滑與無障礙步道改善工程進行中",
            timeText: "前日 09:10",
            createdAt: Date()
        )
    ]
    private(set) var favoriteFacilityIDs: Set<Facility.ID> = [] {
        didSet {
            saveFavorites()
        }
    }

    var selectedFacility: Facility? {
        facilities.first { $0.id == selectedFacilityID }
    }

    func liveNews(for facilityID: Facility.ID) -> [LiveNewsItem] {
        liveNewsItems.filter { $0.facilityID == facilityID }
    }

    var availableCities: [String] {
        Array(Set(facilities.map(\.city))).sorted()
    }

    var availableDistricts: [String] {
        let scopedFacilities = facilities.filter { facility in
            guard let selectedCity else { return true }
            return facility.city == selectedCity
        }
        return Array(Set(scopedFacilities.map(\.district))).sorted()
    }

    var hasAdvancedFilters: Bool {
        !requiredFeatures.isEmpty || selectedCity != nil || selectedDistrict != nil
    }

    func isFavorite(_ facilityID: Facility.ID) -> Bool {
        favoriteFacilityIDs.contains(facilityID)
    }

    func toggleFavorite(_ facilityID: Facility.ID) {
        if favoriteFacilityIDs.contains(facilityID) {
            favoriteFacilityIDs.remove(facilityID)
        } else {
            favoriteFacilityIDs.insert(facilityID)
        }
    }

    private func saveFavorites() {
        let array = Array(favoriteFacilityIDs)
        UserDefaults.standard.set(array, forKey: "FavoriteFacilityIDs")
    }

    private func loadFavorites() {
        if let saved = UserDefaults.standard.stringArray(forKey: "FavoriteFacilityIDs") {
            favoriteFacilityIDs = Set(saved)
        }
    }

    func clearAdvancedFilters() {
        selectedCity = nil
        selectedDistrict = nil
        requiredFeatures.removeAll()
    }

    func selectCity(_ city: String?) {
        selectedCity = city
        selectedDistrict = nil
    }

    func toggleFeature(_ feature: FacilityFeature) {
        if requiredFeatures.contains(feature) {
            requiredFeatures.remove(feature)
        } else {
            requiredFeatures.insert(feature)
        }
    }

    func loadFacilities() async {
        loadFavorites()
        guard facilities.isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            facilities = try await repository.loadFacilities()
            message = "目前已匯入最新公共設施開放資料庫；包含全台飲水點與優等公廁標的。"
        } catch {
            facilities = []
            message = "資料載入失敗，請稍後再試。"
        }
    }

    func searchSuggestions(userLocation: CLLocation?) -> [Facility] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }

        let matches = facilities.filter { facility in
            facility.name.localizedCaseInsensitiveContains(query)
            || facility.address.localizedCaseInsensitiveContains(query)
            || (facility.detailedLocation?.localizedCaseInsensitiveContains(query) ?? false)
            || facility.city.localizedCaseInsensitiveContains(query)
            || facility.district.localizedCaseInsensitiveContains(query)
        }

        return matches.sorted { lhs, rhs in
            guard let userLocation else {
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
            return userLocation.distance(from: lhs.location) < userLocation.distance(from: rhs.location)
        }
    }

    func visibleFacilities(userLocation: CLLocation?) -> [Facility] {
        let normalizedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let queryMatches = facilities.filter { facility in
            facilityMatchesFilter(facility, filter: selectedFilter)
            && requiredFeatures.isSubset(of: facility.computedFeatures)
            && (selectedCity == nil || facility.city == selectedCity)
            && (selectedDistrict == nil || facility.district == selectedDistrict)
            && (normalizedQuery.isEmpty
                || facility.name.localizedCaseInsensitiveContains(normalizedQuery)
                || facility.address.localizedCaseInsensitiveContains(normalizedQuery)
                || (facility.detailedLocation?.localizedCaseInsensitiveContains(normalizedQuery) ?? false))
        }

        return queryMatches.sorted { lhs, rhs in
            guard let userLocation else {
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }

            return userLocation.distance(from: lhs.location) < userLocation.distance(from: rhs.location)
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

    func searchRegion() async -> MKCoordinateRegion? {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchedCoordinate = nil
            return nil
        }

        if let matchedFacility = facilities.first(where: { facility in
            facility.name.localizedCaseInsensitiveContains(query)
            || facility.address.localizedCaseInsensitiveContains(query)
            || (facility.detailedLocation?.localizedCaseInsensitiveContains(query) ?? false)
        }) {
            selectedFacilityID = matchedFacility.id
            searchedCoordinate = matchedFacility.coordinate
            return MKCoordinateRegion(center: matchedFacility.coordinate, latitudinalMeters: 900, longitudinalMeters: 900)
        }

        do {
            let searchRequest = MKLocalSearch.Request()
            searchRequest.naturalLanguageQuery = query
            let search = MKLocalSearch(request: searchRequest)
            let response = try await search.start()
            guard let mapItem = response.mapItems.first else {
                message = "找不到「\(query)」的相對應地點。"
                return nil
            }

            let coordinate = mapItem.placemark.coordinate
            searchedCoordinate = coordinate
            message = "已定位至「\(query)」附近。"
            return MKCoordinateRegion(center: coordinate, latitudinalMeters: 1200, longitudinalMeters: 1200)
        } catch {
            message = "搜尋地點時發生錯誤。"
            return nil
        }
    }

    func submitIssueReport(facilityID: Facility.ID, category: IssueCategory, detail: String, contact: String) {
        guard let facility = facilities.first(where: { $0.id == facilityID }) else { return }

        let report = IssueReport(
            id: UUID(),
            facilityID: facilityID,
            facilityName: facility.name,
            category: category,
            detail: detail,
            contact: contact,
            createdAt: Date()
        )

        issueReports.insert(report, at: 0)

        // 使用者回報同步新增到即時情況動態分頁 (Live News)
        let liveNews = LiveNewsItem(
            id: UUID().uuidString,
            facilityID: facilityID,
            status: .reported,
            facilityName: facility.name,
            locationText: "\(facility.city)\(facility.district)",
            title: "【使用者回報】\(category.title)：\(detail)",
            timeText: "剛剛",
            createdAt: Date()
        )

        liveNewsItems.insert(liveNews, at: 0)
    }
}

struct FacilityRepository {
    func loadFacilities() async throws -> [Facility] {
        FacilitySampleData.facilities
    }
}

private enum FacilitySampleData {
    static let facilities: [Facility] = [
        // 台北 / 新北 核心交通與景點
        Facility(
            id: "water-tpe-main-station",
            name: "台北車站公共飲水點",
            type: .drinkingWater,
            latitude: 25.04776,
            longitude: 121.51706,
            address: "台北市中正區北平西路3號",
            detailedLocation: "車站1樓大廳東側，靠近1號出口詢問處旁",
            waterTemperatures: [.cold, .warm, .hot],
            openingHours: "每日 05:00 - 24:00 (依車站營運時間)",
            features: [.accessible, .indoor, .comboFacility],
            sourceName: "臺北市政府開放資料",
            lastUpdated: "2026-03-01"
        ),
        Facility(
            id: "toilet-tpe-main-station",
            name: "台北車站公廁",
            type: .restroom,
            latitude: 25.04790,
            longitude: 121.51730,
            address: "台北市中正區北平西路3號",
            detailedLocation: "車站地下一樓層東側通道旁",
            waterTemperatures: nil,
            openingHours: "每日 05:00 - 24:00 (依車站營運時間)",
            features: [.accessible, .familyFriendly, .genderInclusive, .indoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-05"
        ),
        Facility(
            id: "water-da-an-park",
            name: "大安森林公園飲水台",
            type: .drinkingWater,
            latitude: 25.03038,
            longitude: 121.53580,
            address: "台北市大安區新生南路二段1號",
            detailedLocation: "公園中央露天音樂台後方步道旁",
            waterTemperatures: [.cold, .warm],
            openingHours: "24 小時全天候開放",
            features: [.accessible, .openAllDay, .outdoor, .comboFacility],
            sourceName: "臺北市公園路燈工程管理處",
            lastUpdated: "2026-02-28"
        ),
        Facility(
            id: "toilet-da-an-park",
            name: "大安森林公園公廁",
            type: .restroom,
            latitude: 25.03112,
            longitude: 121.53490,
            address: "台北市大安區新生南路二段1號",
            detailedLocation: "建國南路二段側門入口右手邊第1座公廁",
            waterTemperatures: nil,
            openingHours: "24 小時全天候開放",
            features: [.accessible, .familyFriendly, .openAllDay, .outdoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-02"
        ),

        // CSV 地標：鶯歌區
        Facility(
            id: "F080000279",
            name: "中油鶯歌加油站男廁",
            type: .restroom,
            latitude: 24.95042700,
            longitude: 121.35223700,
            address: "新北市鶯歌區南靖里文化路152號",
            detailedLocation: "加油站站體旁獨立衛生間",
            waterTemperatures: nil,
            openingHours: "每日 06:00 - 22:00",
            features: [.accessible, .outdoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-12"
        ),
        Facility(
            id: "F080000297",
            name: "麥當勞鶯歌文化店",
            type: .restroom,
            latitude: 24.95109200,
            longitude: 121.35228900,
            address: "新北市鶯歌區南靖里文化路363號",
            detailedLocation: "餐廳1樓專用洗洗間",
            waterTemperatures: nil,
            openingHours: "每日 06:00 - 24:00",
            features: [.accessible, .familyFriendly, .indoor],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-10"
        ),

        // CSV 地標：三峽區
        Facility(
            id: "F090000007",
            name: "三峽祖師廟男廁",
            type: .restroom,
            latitude: 24.93380000,
            longitude: 121.37036700,
            address: "新北市三峽區秀川里長福街1號",
            detailedLocation: "祖師廟正殿左側香客服務處旁",
            waterTemperatures: nil,
            openingHours: "每日 05:00 - 22:00",
            features: [.accessible, .outdoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-08"
        ),
        Facility(
            id: "F090000305",
            name: "滿月圓森林遊樂區",
            type: .restroom,
            latitude: 24.82214572,
            longitude: 121.44907240,
            address: "新北市三峽區有木里有木174-1號",
            detailedLocation: "遊客中心旁休憩廣場側門",
            waterTemperatures: nil,
            openingHours: "每日 08:00 - 17:00",
            features: [.accessible, .outdoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-11"
        ),
        Facility(
            id: "F090000126",
            name: "歷史文物館男廁",
            type: .restroom,
            latitude: 24.93452600,
            longitude: 121.36935200,
            address: "新北市三峽區永館里中山路18號",
            detailedLocation: "文物館後方文化園區展覽廳旁",
            waterTemperatures: nil,
            openingHours: "週二至週日 09:00 - 17:00",
            features: [.accessible, .indoor],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-05"
        ),
        Facility(
            id: "F090000278",
            name: "三峽白雞行修宮男廁",
            type: .restroom,
            latitude: 24.90511193,
            longitude: 121.40021320,
            address: "新北市三峽區嘉添里白雞155號",
            detailedLocation: "觀光景觀庭園與停車場連通道",
            waterTemperatures: nil,
            openingHours: "每日 05:00 - 21:00",
            features: [.accessible, .openAllDay, .outdoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-09"
        ),
        Facility(
            id: "F090000299",
            name: "大板根森林遊樂區飲水點",
            type: .drinkingWater,
            latitude: 24.87088700,
            longitude: 121.40731200,
            address: "新北市三峽區插角里插角80號",
            detailedLocation: "渡假酒店大廳與椰林大道入口處",
            waterTemperatures: [.cold, .warm, .hot],
            openingHours: "每日 07:00 - 22:00",
            features: [.accessible, .indoor, .comboFacility],
            sourceName: "新北市政府開放資料",
            lastUpdated: "2026-03-12"
        ),

        // CSV 地標：淡水區
        Facility(
            id: "F100000147",
            name: "淡水無極天元宮男廁",
            type: .restroom,
            latitude: 25.18637929,
            longitude: 121.48499250,
            address: "新北市淡水區水源里北新路3段36號",
            detailedLocation: "天壇圓池右後方與停車場區域旁",
            waterTemperatures: nil,
            openingHours: "每日 06:30 - 20:30",
            features: [.accessible, .familyFriendly, .outdoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-10"
        ),
        Facility(
            id: "F100000428",
            name: "淡水紅毛城男廁",
            type: .restroom,
            latitude: 25.17478640,
            longitude: 121.43321514,
            address: "新北市淡水區文化里中正路28巷1號",
            detailedLocation: "古蹟園區售票口後方文創商品館旁",
            waterTemperatures: nil,
            openingHours: "每日 09:30 - 17:00",
            features: [.accessible, .genderInclusive, .outdoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-11"
        ),
        Facility(
            id: "F100000386",
            name: "淡水福佑宮女廁",
            type: .restroom,
            latitude: 25.17006000,
            longitude: 121.43990000,
            address: "新北市淡水區民安里中正路200號",
            detailedLocation: "淡水老街福佑宮側門川堂",
            waterTemperatures: nil,
            openingHours: "每日 06:00 - 21:00",
            features: [.accessible, .indoor],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-02"
        ),
        Facility(
            id: "F100000501",
            name: "漁人碼頭北邊停車場女廁",
            type: .restroom,
            latitude: 25.18139500,
            longitude: 121.41677700,
            address: "新北市淡水區沙崙里觀海路199號",
            detailedLocation: "木棧道觀景平台情人橋對面",
            waterTemperatures: nil,
            openingHours: "24 小時全天候開放",
            features: [.accessible, .familyFriendly, .openAllDay, .outdoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-09"
        ),

        // CSV 地標：板橋區
        Facility(
            id: "water-banqiao-station",
            name: "板橋車站飲水機",
            type: .drinkingWater,
            latitude: 25.01429,
            longitude: 121.46381,
            address: "新北市板橋區縣民大道二段7號",
            detailedLocation: "地下一樓鐵路剪票口左側，靠近環球購物中心連通道",
            waterTemperatures: [.cold, .warm, .hot],
            openingHours: "每日 06:00 - 23:30 (依車站與商場營運時間)",
            features: [.accessible, .indoor, .comboFacility],
            sourceName: "新北市政府開放資料",
            lastUpdated: "2026-03-10"
        ),
        Facility(
            id: "toilet-banqiao-station",
            name: "板橋車站公廁",
            type: .restroom,
            latitude: 25.01450,
            longitude: 121.46410,
            address: "新北市板橋區縣民大道二段7號",
            detailedLocation: "2樓餐廳街南側洗手專區",
            waterTemperatures: nil,
            openingHours: "每日 06:00 - 23:30 (依車站營運時間)",
            features: [.accessible, .familyFriendly, .genderInclusive, .indoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-11"
        ),
        Facility(
            id: "F010001852",
            name: "華德公園男廁",
            type: .restroom,
            latitude: 24.99259800,
            longitude: 121.45346200,
            address: "新北市板橋區華德里四川路二段245巷125號",
            detailedLocation: "公園涼亭活動中心旁側門入口",
            waterTemperatures: nil,
            openingHours: "24 小時全天候開放",
            features: [.accessible, .openAllDay, .outdoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-04"
        ),
        Facility(
            id: "F010001906",
            name: "捷運亞東醫院站女廁",
            type: .restroom,
            latitude: 24.99777900,
            longitude: 121.45242700,
            address: "新北市板橋區華東里南雅南路2段17號",
            detailedLocation: "捷運穿堂層3號出口改札口旁",
            waterTemperatures: nil,
            openingHours: "每日 06:00 - 24:00",
            features: [.accessible, .familyFriendly, .indoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-06"
        ),

        // CSV 地標：新莊區
        Facility(
            id: "F050000287",
            name: "宜家家居新莊店無障礙廁所",
            type: .restroom,
            latitude: 25.04128817,
            longitude: 121.46503925,
            address: "新北市新莊區文明里中正路1號",
            detailedLocation: "1樓顧客服務中心與美食小吃區旁",
            waterTemperatures: nil,
            openingHours: "每日 10:00 - 22:00",
            features: [.accessible, .familyFriendly, .indoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-07"
        ),
        Facility(
            id: "F050000181",
            name: "新莊第一公有零售市場女廁",
            type: .restroom,
            latitude: 25.03413700,
            longitude: 121.45321900,
            address: "新北市新莊區榮和里新莊路313巷",
            detailedLocation: "市場1樓熟食攤區底側門",
            waterTemperatures: nil,
            openingHours: "每日 06:00 - 15:00",
            features: [.accessible, .indoor],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-01"
        ),

        // CSV 地標：新店區
        Facility(
            id: "F060000150",
            name: "碧潭西岸女廁",
            type: .restroom,
            latitude: 24.95632800,
            longitude: 121.53512300,
            address: "新北市新店區太平里碧潭西岸吊橋下",
            detailedLocation: "吊橋西端水岸步道左側公園處",
            waterTemperatures: nil,
            openingHours: "24 小時全天候開放",
            features: [.accessible, .openAllDay, .outdoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-12"
        ),
        Facility(
            id: "F060000141",
            name: "捷運大坪林站女廁",
            type: .restroom,
            latitude: 24.98358500,
            longitude: 121.54146800,
            address: "新北市新店區寶安里北新路3段190號",
            detailedLocation: "地下1樓穿堂層1號出口連通道旁",
            waterTemperatures: nil,
            openingHours: "每日 06:00 - 24:00",
            features: [.accessible, .familyFriendly, .indoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-09"
        ),

        // CSV 地標：三重區
        Facility(
            id: "F020000276",
            name: "中油菜寮加油站男廁",
            type: .restroom,
            latitude: 25.05890400,
            longitude: 121.48964400,
            address: "新北市三重區過田里重新路3段157號",
            detailedLocation: "重新路與重陽路交叉口加油站旁",
            waterTemperatures: nil,
            openingHours: "24 小時全天候開放",
            features: [.accessible, .openAllDay, .outdoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-11"
        ),
        Facility(
            id: "F020001656",
            name: "三重先嗇宮男廁",
            type: .restroom,
            latitude: 25.05039400,
            longitude: 121.47613500,
            address: "新北市三重區五谷里五谷王北街77號",
            detailedLocation: "廟宇右側庭園旁專用洗洗間",
            waterTemperatures: nil,
            openingHours: "每日 05:00 - 21:00",
            features: [.accessible, .outdoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-04"
        ),

        // CSV 地標：中和區
        Facility(
            id: "F030000333",
            name: "八二三紀念公園性別友善廁所",
            type: .restroom,
            latitude: 24.99985500,
            longitude: 121.51140000,
            address: "新北市中和區安樂里中安街派出所後",
            detailedLocation: "國立臺灣圖書館後方公園步道旁",
            waterTemperatures: nil,
            openingHours: "24 小時全天候開放",
            features: [.accessible, .genderInclusive, .openAllDay, .outdoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-12"
        ),
        Facility(
            id: "F030000580",
            name: "中和南山福德宮男廁",
            type: .restroom,
            latitude: 24.97274300,
            longitude: 121.49771300,
            address: "新北市中和區內南里興南路2段399巷160-1號",
            detailedLocation: "烘爐地正殿入口大石獅下方平台",
            waterTemperatures: nil,
            openingHours: "24 小時全天候開放",
            features: [.accessible, .openAllDay, .outdoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-08"
        ),

        // CSV 地標：汐止區
        Facility(
            id: "F110000168",
            name: "汐止長安圖書館混合廁所",
            type: .restroom,
            latitude: 25.07833000,
            longitude: 121.66954900,
            address: "新北市汐止區長安里長興街一段50號",
            detailedLocation: "圖書館3樓展覽與閱覽大廳邊角",
            waterTemperatures: nil,
            openingHours: "週二至週日 08:30 - 21:00",
            features: [.accessible, .genderInclusive, .indoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-03"
        ),
        Facility(
            id: "F110000067",
            name: "汐止火車站男廁",
            type: .restroom,
            latitude: 25.06831600,
            longitude: 121.66173460,
            address: "新北市汐止區信望里信義路1號",
            detailedLocation: "2樓北側剪票大廳側門",
            waterTemperatures: nil,
            openingHours: "每日 05:30 - 23:30",
            features: [.accessible, .indoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-07"
        ),

        // CSV 地標：瑞芳區
        Facility(
            id: "F120000002",
            name: "瑞芳火車站女廁",
            type: .restroom,
            latitude: 25.10875190,
            longitude: 121.80608080,
            address: "新北市瑞芳區龍潭里明燈路三段82號",
            detailedLocation: "站體地下穿堂連通道出口旁",
            waterTemperatures: nil,
            openingHours: "每日 05:00 - 23:30",
            features: [.accessible, .indoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-10"
        ),
        Facility(
            id: "F120000177",
            name: "九份遊客中心無障礙廁所",
            type: .restroom,
            latitude: 25.10975000,
            longitude: 121.84347000,
            address: "新北市瑞芳區頌德里汽車路89號",
            detailedLocation: "九份老道入口遊客中心大廳",
            waterTemperatures: nil,
            openingHours: "每日 08:00 - 18:00",
            features: [.accessible, .indoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-09"
        ),
        Facility(
            id: "F120000137",
            name: "猴硐火車站女廁",
            type: .restroom,
            latitude: 25.08681000,
            longitude: 121.82753000,
            address: "新北市瑞芳區光復里柴寮路70號",
            detailedLocation: "貓村天橋出口火車站1樓大廳",
            waterTemperatures: nil,
            openingHours: "每日 06:00 - 22:00",
            features: [.accessible, .outdoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-06"
        ),

        // CSV 地標：宜蘭縣 (礁溪, 羅東)
        Facility(
            id: "G050000058",
            name: "礁溪協天廟女廁",
            type: .restroom,
            latitude: 24.81859918,
            longitude: 121.76892042,
            address: "宜蘭縣礁溪鄉大義村中山路一段51號",
            detailedLocation: "廟宇香客大樓東側川堂",
            waterTemperatures: nil,
            openingHours: "每日 06:00 - 21:30",
            features: [.accessible, .outdoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-05"
        ),
        Facility(
            id: "G050000019",
            name: "湯圍溝公園無障礙廁所",
            type: .restroom,
            latitude: 24.82750785,
            longitude: 121.77107960,
            address: "宜蘭縣礁溪鄉德陽村仁愛路15巷6號",
            detailedLocation: "公園免費泡腳池後方休憩區",
            waterTemperatures: nil,
            openingHours: "24 小時全天候開放",
            features: [.accessible, .openAllDay, .outdoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-08"
        ),
        Facility(
            id: "G020000003",
            name: "羅東火車站男廁",
            type: .restroom,
            latitude: 24.67799734,
            longitude: 121.77447367,
            address: "宜蘭縣羅東鎮大新里公正路2號",
            detailedLocation: "前站售票大廳右側通道",
            waterTemperatures: nil,
            openingHours: "每日 05:00 - 24:00",
            features: [.accessible, .indoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-12"
        ),

        // CSV 地標：台中市
        Facility(
            id: "water-taichung-park",
            name: "台中公園飲水台",
            type: .drinkingWater,
            latitude: 24.14470,
            longitude: 120.68412,
            address: "台中市北區公園路37-1號",
            detailedLocation: "湖心亭觀景平台入口斜對面",
            waterTemperatures: [.cold, .warm],
            openingHours: "24 小時全天候開放",
            features: [.accessible, .openAllDay, .outdoor],
            sourceName: "臺中市政府開放資料",
            lastUpdated: "2026-02-25"
        ),
        Facility(
            id: "toilet-taichung-station",
            name: "台中車站公廁",
            type: .restroom,
            latitude: 24.13682,
            longitude: 120.68501,
            address: "台中市中區台灣大道一段1號",
            detailedLocation: "新站體2樓大廳售票窗口右側",
            waterTemperatures: nil,
            openingHours: "每日 05:30 - 23:30 (依車站營運時間)",
            features: [.accessible, .familyFriendly, .indoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-08"
        ),

        // CSV 地標：臺南市
        Facility(
            id: "D270000154",
            name: "奇美博物館女廁",
            type: .restroom,
            latitude: 22.93445100,
            longitude: 120.22620900,
            address: "臺南市仁德區成功村文華路二段66號",
            detailedLocation: "展覽區3F南側迴廊專區",
            waterTemperatures: nil,
            openingHours: "週一至週日 09:30 - 17:30 (週三休館)",
            features: [.accessible, .familyFriendly, .indoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-10"
        ),
        Facility(
            id: "D280000105",
            name: "歸仁文化中心男廁",
            type: .restroom,
            latitude: 22.96410300,
            longitude: 120.29805900,
            address: "臺南市歸仁區許厝村信義南路78號",
            detailedLocation: "行政大樓1F演藝廳中庭",
            waterTemperatures: nil,
            openingHours: "週二至週日 09:00 - 17:00",
            features: [.accessible, .familyFriendly, .indoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-04"
        ),

        // CSV 地標：高雄市
        Facility(
            id: "E120000393",
            name: "鳳山婦幼青少年館男廁",
            type: .restroom,
            latitude: 22.62989200,
            longitude: 120.34742400,
            address: "高雄市鳳山區忠孝里光復路2段120號",
            detailedLocation: "東側1樓大廳服務台後方",
            waterTemperatures: nil,
            openingHours: "週二至週日 08:30 - 21:00",
            features: [.accessible, .familyFriendly, .genderInclusive, .indoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-09"
        ),
        Facility(
            id: "E180000002",
            name: "澄清湖風景區女廁",
            type: .restroom,
            latitude: 22.65358110,
            longitude: 120.34907700,
            address: "高雄市鳥松區鳥松里大埤路32號",
            detailedLocation: "第一景大門口遊客園區大廳右側",
            waterTemperatures: nil,
            openingHours: "每日 06:00 - 18:00",
            features: [.accessible, .outdoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-12"
        ),

        // CSV 地標：嘉義市
        Facility(
            id: "I010000803",
            name: "耐斯百貨男廁",
            type: .restroom,
            latitude: 23.49694100,
            longitude: 120.45241400,
            address: "嘉義市東區義教里忠孝路600號",
            detailedLocation: "耐斯廣場百貨8F主題餐廳區旁",
            waterTemperatures: nil,
            openingHours: "每日 11:00 - 22:00",
            features: [.accessible, .familyFriendly, .indoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-07"
        ),
        Facility(
            id: "I020000674",
            name: "嘉義火車站男廁",
            type: .restroom,
            latitude: 23.47925159,
            longitude: 120.44136460,
            address: "嘉義市西區番社里中山路528號",
            detailedLocation: "前站候車大廳1號月台側",
            waterTemperatures: nil,
            openingHours: "每日 05:00 - 24:00",
            features: [.accessible, .indoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-11"
        ),

        // CSV 地標：臺東縣
        Facility(
            id: "V010000178",
            name: "臺東市戶政事務所性別友善廁所",
            type: .restroom,
            latitude: 22.75425000,
            longitude: 121.14711110,
            address: "臺東縣臺東市文化里信義路291號",
            detailedLocation: "事務所1樓服務大廳側邊",
            waterTemperatures: nil,
            openingHours: "週一至週五 08:00 - 17:30",
            features: [.accessible, .genderInclusive, .indoor],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-02"
        ),
        Facility(
            id: "V110000020",
            name: "綠島加油站無障礙廁所",
            type: .restroom,
            latitude: 22.66062330,
            longitude: 121.47526415,
            address: "臺東縣綠島鄉南寮村漁港路7號",
            detailedLocation: "綠島南寮漁港加油站附設衛生間",
            waterTemperatures: nil,
            openingHours: "每日 07:00 - 18:00",
            features: [.accessible, .outdoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-08"
        ),
        Facility(
            id: "V110000002",
            name: "綠島人權紀念公園男廁",
            type: .restroom,
            latitude: 22.67525352,
            longitude: 121.49470210,
            address: "臺東縣綠島鄉公館村將軍岩20號",
            detailedLocation: "將軍岩遊客中心展覽館右側",
            waterTemperatures: nil,
            openingHours: "每日 08:30 - 17:30",
            features: [.accessible, .outdoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-09"
        ),
        Facility(
            id: "water-hualien-station",
            name: "花蓮車站飲水機",
            type: .drinkingWater,
            latitude: 23.99331,
            longitude: 121.60122,
            address: "花蓮縣花蓮市國聯一路100號",
            detailedLocation: "3樓跨站式候車大廳自動售票機左側",
            waterTemperatures: [.cold, .warm, .hot],
            openingHours: "每日 05:00 - 23:30 (依車站營運時間)",
            features: [.accessible, .indoor, .comboFacility],
            sourceName: "花蓮縣政府開放資料",
            lastUpdated: "2026-03-09"
        ),
        Facility(
            id: "toilet-hualien-station",
            name: "花蓮車站公廁",
            type: .restroom,
            latitude: 23.99350,
            longitude: 121.60150,
            address: "花蓮縣花蓮市國聯一路100號",
            detailedLocation: "3樓大廳西霸商場連通道口旁",
            waterTemperatures: nil,
            openingHours: "每日 05:00 - 23:30 (依車站營運時間)",
            features: [.accessible, .familyFriendly, .indoor, .comboFacility],
            sourceName: "環境部公共廁所資料庫",
            lastUpdated: "2026-03-09"
        )
    ]
}
