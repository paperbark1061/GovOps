import SwiftUI

struct JobListView: View {
    @EnvironmentObject var dataService: DataService
    @State private var filters = JobFilters()
    @State private var isFilterSheetPresented = false
    @State private var isRefreshing = false

    var filteredOpportunities: [Opportunity] {
        dataService.opportunities.filter { filters.matches($0) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if dataService.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)

                        Text("Loading opportunities...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else if let errorMessage = dataService.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.red)

                        Text("Error Loading Data")
                            .font(.headline)

                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button(action: { dataService.refreshData() }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Retry")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else if filteredOpportunities.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "briefcase")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)

                        Text(filters.hasActiveFilters ? "No Opportunities Match" : "No Opportunities Found")
                            .font(.headline)

                        Text(filters.hasActiveFilters ?
                            "Try adjusting your filters to see more results." :
                            "Opportunities will appear here when data is available.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        if filters.hasActiveFilters {
                            Button(action: resetFilters) {
                                HStack {
                                    Image(systemName: "xmark.circle")
                                    Text("Clear Filters")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else {
                    List {
                        ForEach(filteredOpportunities) { opportunity in
                            NavigationLink(destination: JobDetailView(opportunity: opportunity)) {
                                JobListRow(opportunity: opportunity)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        isRefreshing = true
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        dataService.refreshData()
                        isRefreshing = false
                    }
                }
            }
            .navigationTitle("GovOps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 8) {
                        NavigationLink(destination: CompanyListView()) {
                            Image(systemName: "building.2")
                                .foregroundColor(.blue)
                        }

                        Button(action: { isFilterSheetPresented = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .foregroundColor(.blue)

                                if filters.hasActiveFilters {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                }
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $isFilterSheetPresented) {
                FilterView(filters: $filters)
            }
        }
    }

    private func resetFilters() {
        filters = JobFilters()
    }
}

struct JobListRow: View {
    let opportunity: Opportunity

    var moduleColor: Color {
        switch opportunity.module.lowercased() {
        case let m where m.contains("labour"):
            return .blue
        case let m where m.contains("professional"):
            return .green
        case let m where m.contains("rfi"):
            return .orange
        default:
            return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(opportunity.title)
                        .font(.headline)
                        .lineLimit(2)

                    Text(opportunity.buyer)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(opportunity.module)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(moduleColor.opacity(0.2))
                        .foregroundColor(moduleColor)
                        .cornerRadius(4)

                    Text(opportunity.location)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 12) {
                Label(opportunity.arrangement, systemImage: "building")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("Closes: \(opportunity.closing)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if !opportunity.skills.isEmpty {
                HStack(spacing: 6) {
                    ForEach(opportunity.skills.prefix(3), id: \.self) { skill in
                        Text(skill)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }

                    if opportunity.skills.count > 3 {
                        Text("+\(opportunity.skills.count - 3)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    JobListView()
        .environmentObject(DataService.shared)
}