import SwiftUI

struct ReportIssueView: View {
    @Bindable var viewModel: FacilityViewModel
    @Binding var selectedSubTab: ReportSubTab
    var onSelectFacilityOnMap: ((Facility) -> Void)? = nil

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
                    LiveNewsSubView(viewModel: viewModel, onSelectFacilityOnMap: onSelectFacilityOnMap)
                }
            }
            .navigationTitle("設施回報專區")
        }
    }
}

enum ReportSubTab: String, CaseIterable, Identifiable {
    case submit = "回報系統"
    case recent = "最近回報"
    case news = "即時情況動態"

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
                Text("回報成功後，將即時同步更新至「即時情況動態」分頁與地圖上該設施的詳細資訊卡中。")
            }

            if didSubmit {
                Section {
                    Label("已收到回報，並已即時更新至首頁地圖設施詳細資訊與即時情況動態！", systemImage: "checkmark.circle.fill")
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

// MARK: - SubView 3: 即時情況動態分頁 (Live Report Bulletins)
struct LiveNewsSubView: View {
    @Bindable var viewModel: FacilityViewModel
    var onSelectFacilityOnMap: ((Facility) -> Void)? = nil

    var body: some View {
        List {
            Section {
                HStack(spacing: 8) {
                    Image(systemName: "bell.badge.fill")
                        .foregroundStyle(.blue)
                    Text("全台公共水廁維護、清潔與使用者通報最新動態")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }

            ForEach(viewModel.liveNewsItems) { item in
                Button {
                    if let facilityID = item.facilityID,
                       let facility = viewModel.facilities.first(where: { $0.id == facilityID }) {
                        onSelectFacilityOnMap?(facility)
                    }
                } label: {
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

                            if item.facilityID != nil {
                                Spacer()
                                Text("在地圖查看 ▶")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.accentColor)
                            }
                        }

                        Text(item.title)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.insetGrouped)
    }
}

#Preview {
    ReportIssueView(viewModel: FacilityViewModel(), selectedSubTab: .constant(.submit))
}
