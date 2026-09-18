import SwiftUI

struct AdvancedFilterView: View {
    @Bindable var viewModel: FacilityViewModel
    @Environment(\.dismiss) private var dismiss

    private var drinkingWaterFeatures: [FacilityFeature] {
        [.hasColdWater, .hasWarmWater, .hasHotWater]
    }

    private var restroomFeatures: [FacilityFeature] {
        [.accessible, .familyFriendly, .genderInclusive]
    }

    private var generalFeatures: [FacilityFeature] {
        [.openAllDay, .indoor, .outdoor, .comboFacility]
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("行政區位置") {
                    Picker("縣市", selection: cityBinding) {
                        Text("全部縣市").tag(String?.none)
                        ForEach(viewModel.availableCities, id: \.self) { city in
                            Text(city).tag(String?.some(city))
                        }
                    }

                    Picker("鄉鎮市區", selection: districtBinding) {
                        Text("全部鄉鎮市區").tag(String?.none)
                        ForEach(viewModel.availableDistricts, id: \.self) { district in
                            Text(district).tag(String?.some(district))
                        }
                    }
                    .disabled(viewModel.availableDistricts.isEmpty)
                }

                Section("飲水機篩選條件") {
                    ForEach(drinkingWaterFeatures) { feature in
                        Toggle(isOn: featureBinding(feature)) {
                            Label {
                                Text(feature.title)
                            } icon: {
                                Image(systemName: feature.symbolName)
                                    .foregroundStyle(.cyan)
                            }
                        }
                    }
                }

                Section("廁所篩選條件") {
                    ForEach(restroomFeatures) { feature in
                        Toggle(isOn: featureBinding(feature)) {
                            Label {
                                Text(feature.title)
                            } icon: {
                                Image(systemName: feature.symbolName)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }

                Section("通用與開放條件") {
                    ForEach(generalFeatures) { feature in
                        Toggle(isOn: featureBinding(feature)) {
                            Label {
                                Text(feature.title)
                            } icon: {
                                Image(systemName: feature.symbolName)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }

                Section {
                    Button("清除進階篩選") {
                        viewModel.clearAdvancedFilters()
                    }
                    .disabled(!viewModel.hasAdvancedFilters)
                }
            }
            .navigationTitle("進階篩選")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var cityBinding: Binding<String?> {
        Binding(
            get: { viewModel.selectedCity },
            set: { viewModel.selectCity($0) }
        )
    }

    private var districtBinding: Binding<String?> {
        Binding(
            get: { viewModel.selectedDistrict },
            set: { viewModel.selectedDistrict = $0 }
        )
    }

    private func featureBinding(_ feature: FacilityFeature) -> Binding<Bool> {
        Binding(
            get: { viewModel.requiredFeatures.contains(feature) },
            set: { _ in
                viewModel.toggleFeature(feature)
            }
        )
    }
}

#Preview {
    AdvancedFilterView(viewModel: FacilityViewModel())
}
