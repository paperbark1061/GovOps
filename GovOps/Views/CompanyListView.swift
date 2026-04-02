import SwiftUI

struct CompanyListView: View {
    @EnvironmentObject var dataService: DataService
    @State private var searchText = ""
    @State private var showActiveOnly = false
    @State private var selectedPanel = "All"

    let panelFilters = ["All", "BuyICT", "NSW", "VIC", "QLD", "SA", "WA", "TAS", "NT", "ACT"]

    var filteredCompanies: [Company] {
        var results = dataService.companies

        if showActiveOnly {
            results = results.filter { $0.isAdvertising }
        }

        if selectedPanel != "All" {
            results = results.filter { company in
                company.panels?.contains { panel in
                    panel.jurisdiction.lowercased().contains(selectedPanel.lowercased()) ||
                    panel.panelName.lowercased().contains(selectedPanel.lowercased())
                } ?? false
            }
        }

        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            results = results.filter { company in
                company.name.lowercased().contains(searchLower) ||
                company.advertisingRoles.contains { $0.lowercased().contains(searchLower) } ||
                (company.specialties ?? []).contains { $0.lowercased().contains(searchLower) }
            }
        }

        return results.sorted { a, b in
            if a.isAdvertising != b.isAdvertising { return a.isAdvertising }
            return a.name < b.name
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Panel filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(panelFilters, id: \.self) { panel in
                            Button {
                                selectedPanel = panel
                            } label: {
                                Text(panel)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(selectedPanel == panel ? Color.blue : Color(.systemGray6))
                                    .foregroundColor(selectedPanel == panel ? .white : .primary)
                                    .cornerRadius(16)
                            }
                        }

                        Divider()
                            .frame(height: 20)

                        Button {
                            showActiveOnly.toggle()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: showActiveOnly ? "checkmark.circle.fill" : "circle")
                                    .font(.caption2)
                                Text("Active Only")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(showActiveOnly ? Color.green.opacity(0.2) : Color(.systemGray6))
                            .foregroundColor(showActiveOnly ? .green : .primary)
                            .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .background(Color(.systemBackground))

                // Company list
                if filteredCompanies.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "building.2")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)

                        Text(searchText.isEmpty ? "No Companies Found" : "No Results")
                            .font(.headline)

                        Text("Try adjusting your filters or search terms.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else {
                    List {
                        ForEach(filteredCompanies) { company in
                            NavigationLink(destination: CompanyDetailView(company: company)) {
                                CompanyListRow(company: company)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .searchable(text: $searchText, prompt: "Search companies, specialties...")
            .navigationTitle("Companies (\(filteredCompanies.count))")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CompanyListRow: View {
    let company: Company

    var opportunityCount: String {
        let roles = company.advertisingRoles
        if roles.isEmpty { return "" }
        return "\(roles.count) role type\(roles.count == 1 ? "" : "s")"
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(company.isAdvertising ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(width: 44, height: 44)
                Text(String(company.name.prefix(2)).uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(company.isAdvertising ? .blue : .gray)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(company.name)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if company.isAdvertising {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                    }
                }

                if !company.advertisingRoles.isEmpty {
                    Text(company.advertisingRoles.prefix(3).joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                if let panels = company.panels, !panels.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(Array(Set(panels.map { $0.jurisdiction })).sorted().prefix(3), id: \.self) { jurisdiction in
                            Text(jurisdiction)
                                .font(.system(size: 9))
                                .fontWeight(.medium)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.teal.opacity(0.1))
                                .foregroundColor(.teal)
                                .cornerRadius(3)
                        }
                    }
                }
            }

            Spacer()

            if !company.platforms.isEmpty {
                Text("\(company.platforms.count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    CompanyListView()
        .environmentObject(DataService.shared)
}
