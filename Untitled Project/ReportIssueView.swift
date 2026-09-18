import SwiftUI

struct ReportIssueView: View {
    @Bindable var viewModel: FacilityViewModel
    @Binding var selectedSubTab: ReportSubTab

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("回報選單", selection: $selectedSubTab) {
                    ForEach(ReportSubTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGroupedBackground))

                Divider()

                switch selectedSubTab {
                case .submit:
                    ReportFormSubView(viewModel: viewModel)
                case .recent:
                    RecentReportsSubView(viewModel: viewModel)
                case .news:
                    LiveNewsSubView()
                }
            }
            .navigationTitle("設施回報專區")
        }
    }
}

enum ReportSubTab: String, CaseIterable, Identifiable {
    case submit = "回報系統"
    case recent = "最近回報"
    case news = "即時回報消息"

    var id: Self { self }
}

// MARK: - SubView 1: 回報系統 (Submit Form)
struct ReportFormSubView: View {
    @Bindable var viewModel: FacilityViewModel
    @State private var selectionMethod: ReportSelectionMethod = .direct
    @State private var selectedCity: String?
    @State private var selectedDistrict: String?
    @State private var selectedFacilityID: Facility.ID?
    @State private var selectedCategory: IssueCategory = .unavailable
    @State private var detail = ""
    @State private var contact = ""
    @State private var didSubmit = false

    private enum ReportSelectionMethod: String, CaseIterable, Identifiable {
        case direct = "直接選擇設施"
        case byLocation = "按縣市鄉鎮"

        var id: Self { self }
    }

    private var availableCities: [String] {
        Array(Set(viewModel.facilities.map(\.city))).sorted()
    }

    private var availableDistricts: [String] {
        let scoped = viewModel.facilities.filter { facility in
            guard let selectedCity else { return true }
            return facility.city == selectedCity
        }
        return Array(Set(scoped.map(\.district))).sorted()
    }

    private var filteredFacilities: [Facility] {
        if selectionMethod == .direct {
            return viewModel.facilities
        }
        return viewModel.facilities.filter { facility in
            (selectedCity == nil || facility.city == selectedCity) &&
            (selectedDistrict == nil || facility.district == selectedDistrict)
        }
    }

    private var selectedFacility: Facility? {
        viewModel.facilities.first { $0.id == selectedFacilityID }
    }

    var body: some View {
        Form {
            Section("選擇設施方式") {
                Picker("選擇方式", selection: $selectionMethod) {
                    ForEach(ReportSelectionMethod.allCases) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectionMethod) { _, _ in
                    selectedFacilityID = nil
                    selectedCity = nil
                    selectedDistrict = nil
                }
            }

            if selectionMethod == .byLocation {
                Section("地區位置搜尋") {
                    Picker("縣市", selection: $selectedCity) {
                        Text("請選擇縣市").tag(String?.none)
                        ForEach(availableCities, id: \.self) { city in
                            Text(city).tag(String?.some(city))
                        }
                    }
                    .onChange(of: selectedCity) { _, _ in
                        selectedDistrict = nil
                        selectedFacilityID = nil
                    }

                    Picker("鄉鎮市區", selection: $selectedDistrict) {
                        Text("請選擇鄉鎮市區").tag(String?.none)
                        ForEach(availableDistricts, id: \.self) { district in
                            Text(district).tag(String?.some(district))
                        }
                    }
                    .disabled(availableDistricts.isEmpty)
                    .onChange(of: selectedDistrict) { _, _ in
                        selectedFacilityID = nil
                    }

                    Picker("設施標的", selection: $selectedFacilityID) {
                        Text("請選擇設施").tag(Facility.ID?.none)
                        ForEach(filteredFacilities) { facility in
                            Text("\(facility.name) (\(facility.address))")
                                .tag(Facility.ID?.some(facility.id))
                        }
                    }
                }
            } else {
                Section("設施標的選擇") {
                    Picker("設施標的", selection: $selectedFacilityID) {
                        Text("請選擇設施").tag(Facility.ID?.none)
                        ForEach(viewModel.facilities) { facility in
                            Text("\(facility.name) - \(facility.city)\(facility.district)")
                                .tag(Facility.ID?.some(facility.id))
                        }
                    }
                }
            }

            if let selectedFacility {
                Section("已選設施資訊") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(selectedFacility.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Label {
                            Text("設施地址：\(selectedFacility.address)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } icon: {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundStyle(selectedFacility.type.tint)
                        }

                        if let detailedLocation = selectedFacility.detailedLocation {
                            Label {
                                Text("詳細位置：\(detailedLocation)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } icon: {
                                Image(systemName: "location.north.line")
                                    .foregroundStyle(selectedFacility.type.tint)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            Section("故障與問題種類") {
                Picker("問題類型", selection: $selectedCategory) {
                    ForEach(IssueCategory.allCases) { category in
                        Label {
                            Text(category.title)
                        } icon: {
                            Image(systemName: category.symbolName)
                        }
                        .tag(category)
                    }
                }
            }

            Section("問題描述") {
                TextEditor(text: $detail)
                    .frame(minHeight: 100)
                    .overlay(alignment: .topLeading) {
                        if detail.isEmpty {
                            Text("例如：飲水機沒有水、廁所門鎖故障、標記位置不正確")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }

                TextField("聯絡方式（選填）", text: $contact)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
            }

            Section {
                Button(action: submitReport) {
                    Label("送出回報", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                }
                .disabled(!canSubmit)
            } footer: {
                Text("目前回報會先保存於本機系統中，並會即時於「最近回報」分頁同步顯示。")
            }

            if didSubmit {
                Section {
                    Label("已收到回報，謝謝協助更新資料。", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
        }
        .onAppear(perform: syncSelectedFacility)
        .onChange(of: viewModel.selectedFacilityID) { _, newValue in
            if let newValue,
               let facility = viewModel.facilities.first(where: { $0.id == newValue }) {
                selectedCity = facility.city
                selectedDistrict = facility.district
                selectedFacilityID = facility.id
            } else if newValue == nil {
                selectedCity = nil
                selectedDistrict = nil
                selectedFacilityID = nil
            }
        }
    }

    private var canSubmit: Bool {
        selectedFacilityID != nil && !detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func syncSelectedFacility() {
        if let vmSelected = viewModel.selectedFacilityID,
           let facility = viewModel.facilities.first(where: { $0.id == vmSelected }) {
            selectedCity = facility.city
            selectedDistrict = facility.district
            selectedFacilityID = facility.id
        } else {
            selectedCity = nil
            selectedDistrict = nil
            selectedFacilityID = nil
        }
    }

    private func submitReport() {
        guard let selectedFacilityID else { return }

        viewModel.submitIssueReport(
            facilityID: selectedFacilityID,
            category: selectedCategory,
            detail: detail,
            contact: contact
        )

        SoundManager.shared.playPickupSound()

        detail = ""
        contact = ""
        didSubmit = true
    }
}

// MARK: - SubView 2: 最近回報 (Recent Reports List)
struct RecentReportsSubView: View {
    @Bindable var viewModel: FacilityViewModel

    var body: some View {
        Group {
            if viewModel.issueReports.isEmpty {
                ContentUnavailableView(
                    "尚無最近回報紀錄",
                    systemImage: "tray",
                    description: Text("當您在「回報系統」送出故障或維護建議後，紀錄會即時顯示於此。")
                )
            } else {
                List {
                    ForEach(viewModel.issueReports) { report in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: report.category.symbolName)
                                    .font(.headline)
                                    .foregroundStyle(.orange)

                                Text(report.facilityName)
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(.primary)

                                Spacer()

                                Text(report.createdAt, format: .dateTime.month().day().hour().minute())
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }

                            HStack(spacing: 6) {
                                Text(report.category.title)
                                    .font(.caption.weight(.bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .foregroundStyle(.orange)
                                    .background(Color.orange.opacity(0.12), in: Capsule())

                                if !report.contact.isEmpty {
                                    Text("聯絡：\(report.contact)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Text(report.detail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}

// MARK: - SubView 3: 即時回報消息 (Live Report Bulletins)
struct LiveNewsSubView: View {
    private let newsList: [LiveNewsItem] = [
        LiveNewsItem(
            id: "news-1",
            status: .inProgress,
            facilityName: "台北車站公共飲水點",
            locationText: "台北市中正區",
            title: "飲水機濾芯例行更換與水質品質檢測中",
            timeText: "今日 10:30"
        ),
        LiveNewsItem(
            id: "news-2",
            status: .fixed,
            facilityName: "大安森林公園公廁",
            locationText: "台北市大安區",
            title: "2號無障礙廁所門鎖故障已完成修復作業",
            timeText: "今日 08:15"
        ),
        LiveNewsItem(
            id: "news-3",
            status: .reported,
            facilityName: "板橋車站飲水機",
            locationText: "新北市板橋區",
            title: "溫水燈號閃爍通報，原廠維修技師派員前往中",
            timeText: "昨日 16:40"
        ),
        LiveNewsItem(
            id: "news-4",
            status: .cleaned,
            facilityName: "奇美博物館女廁",
            locationText: "臺南市仁德區",
            title: "全館洗洗間例行高規格消毒與環境深層保養完畢",
            timeText: "昨日 12:00"
        ),
        LiveNewsItem(
            id: "news-5",
            status: .fixed,
            facilityName: "捷運大坪林站公廁",
            locationText: "新北市新店區",
            title: "感應式水龍頭感應模組更換完畢，恢復正常水壓",
            timeText: "前日 14:20"
        ),
        LiveNewsItem(
            id: "news-6",
            status: .inProgress,
            facilityName: "礁溪湯圍溝公園無障礙廁所",
            locationText: "宜蘭縣礁溪鄉",
            title: "周邊地管防滑與無障礙步道改善工程進行中",
            timeText: "前日 09:10"
        )
    ]

    var body: some View {
        List {
            Section {
                HStack(spacing: 8) {
                    Image(systemName: "bell.badge.fill")
                        .foregroundStyle(.blue)
                    Text("全台公共水廁維護與通報最新動態")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }

            ForEach(newsList) { item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(item.status.title)
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .foregroundStyle(item.status.color)
                            .background(item.status.color.opacity(0.15), in: Capsule())

                        Text(item.facilityName)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.primary)

                        Spacer()

                        Text(item.timeText)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(item.locationText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(item.title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.insetGrouped)
    }
}

private struct LiveNewsItem: Identifiable {
    let id: String
    let status: NewsStatus
    let facilityName: String
    let locationText: String
    let title: String
    let timeText: String
}

private enum NewsStatus {
    case inProgress
    case fixed
    case reported
    case cleaned

    var title: String {
        switch self {
        case .inProgress:
            "[維護中]"
        case .fixed:
            "[已修復]"
        case .reported:
            "[通報檢修]"
        case .cleaned:
            "[清潔完畢]"
        }
    }

    var color: Color {
        switch self {
        case .inProgress:
            .orange
        case .fixed:
            .green
        case .reported:
            .red
        case .cleaned:
            .blue
        }
    }
}

#Preview {
    ReportIssueView(viewModel: FacilityViewModel(), selectedSubTab: .constant(.submit))
}
