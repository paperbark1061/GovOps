import SwiftUI

struct CompanyListView: View {
    @EnvironmentObject var dataService: DataService
    @State private var searchText = ""

    var filteredCompanies: [Company] {
        let advertisingCompanies = dataService.getAdvertisingCompanies()

        if searchText.isEmpty {
            return advertisingCompanies
        }

        let searchLower = searchText.lowercased()
        return advertisingCompanies.filter { company in
            company.name.lowercased().contains(searchLower) ||
                company.advertisingRoles.contains { $0.lowercased().contains(searchLower) }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredCompanies.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "building.2")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)

                        Text(searchText.isEmpty ? "No Companies Advertising" : "No Results Found")
                            .font(.headline)

                        if searchText.isEmpty {
                            Text("Companies that are actively advertising ICT roles will appear here.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else {
                    List {
                        ForEach(filteredCompanies) { company in
                            CompanyListRow(company: company)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .searchable(text: $searchText, prompt: "Search companies")
            .navigationTitle("Companies (\(filteredCompanies.count))")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CompanyListRow: View {
    let company: Company

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(company.name)
                        .font(.headline)

                    if !company.advertisingRoles.isEmpty {
                        Text(company.advertisingRoles.prefix(3).joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if company.isAdvertising {
                        Label("Active", systemImage: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }

            if !company.platforms.isEmpty {
                HStack(spacing: 4) {
                    ForEach(company.platforms.prefix(3), id: \.self) { platform in
                        Text(platform)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }

                    if company.platforms.count > 3 {
                        Text("+\(company.platforms.count - 3) more")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }

            // Links row
            HStack(spacing: 12) {
                if let urlString = company.websiteURL, let url = URL(string: urlString) {
                    Link(destination: url) {
                        Label("Website", systemImage: "globe")
                            .font(.caption)
                    }
                }

                if let urlString = company.jobsURL, let url = URL(string: urlString) {
                    Link(destination: url) {
                        Label("Jobs", systemImage: "briefcase")
                            .font(.caption)
                    }
                }

                if let urlString = company.buyictURL, let url = URL(string: urlString) {
                    Link(destination: url) {
                        Label("BuyICT", systemImage: "building.columns")
                            .font(.caption)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    CompanyListView()
        .environmentObject(DataService.shared)
}
