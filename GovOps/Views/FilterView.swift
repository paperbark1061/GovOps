import SwiftUI

struct FilterView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var filters: JobFilters

    let roles = ["Developer", "Analyst", "Tester", "Architect", "Engineer", "Manager", "Cyber", "SAP", "Data", "UX"]
    let locations = ["ACT", "NSW", "VIC", "QLD", "WA", "SA", "TAS", "NT", "Remote", "Hybrid"]
    let arrangements = ["Hybrid", "Remote", "Onsite"]
    let modules = ["ICT Labour Hire", "Professional Services", "RFI"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Role Type") {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(roles, id: \.self) { role in
                            Toggle(role, isOn: Binding(
                                get: { filters.roles.contains(role) },
                                set: { isSelected in
                                    if isSelected {
                                        filters.roles.insert(role)
                                    } else {
                                        filters.roles.remove(role)
                                    }
                                }
                            ))
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Location") {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(locations, id: \.self) { location in
                            Toggle(location, isOn: Binding(
                                get: { filters.locations.contains(location) },
                                set: { isSelected in
                                    if isSelected {
                                        filters.locations.insert(location)
                                    } else {
                                        filters.locations.remove(location)
                                    }
                                }
                            ))
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Arrangement") {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(arrangements, id: \.self) { arrangement in
                            Toggle(arrangement, isOn: Binding(
                                get: { filters.arrangements.contains(arrangement) },
                                set: { isSelected in
                                    if isSelected {
                                        filters.arrangements.insert(arrangement)
                                    } else {
                                        filters.arrangements.remove(arrangement)
                                    }
                                }
                            ))
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Module Type") {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(modules, id: \.self) { module in
                            Toggle(module, isOn: Binding(
                                get: { filters.modules.contains(module) },
                                set: { isSelected in
                                    if isSelected {
                                        filters.modules.insert(module)
                                    } else {
                                        filters.modules.remove(module)
                                    }
                                }
                            ))
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    Button(action: resetFilters) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Reset All Filters")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .tint(.red)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func resetFilters() {
        filters = JobFilters()
    }
}

struct JobFilters {
    var searchText: String = ""
    var roles: Set<String> = []
    var locations: Set<String> = []
    var arrangements: Set<String> = []
    var modules: Set<String> = []

    var hasActiveFilters: Bool {
        !searchText.isEmpty || !roles.isEmpty || !locations.isEmpty || !arrangements.isEmpty || !modules.isEmpty
    }

    func matches(_ opportunity: Opportunity) -> Bool {
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            if !opportunity.title.lowercased().contains(searchLower) &&
                !opportunity.buyer.lowercased().contains(searchLower) &&
                !opportunity.category.lowercased().contains(searchLower) {
                return false
            }
        }

        if !roles.isEmpty {
            let titleLower = opportunity.title.lowercased()
            let matchesRole = roles.contains { role in
                titleLower.contains(role.lowercased())
            }
            if !matchesRole {
                return false
            }
        }

        if !locations.isEmpty {
            let oppLocations = opportunity.location.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            let matchesLocation = locations.contains { loc in
                oppLocations.contains(loc) || opportunity.arrangement.lowercased() == loc.lowercased()
            }
            if !matchesLocation {
                return false
            }
        }

        if !arrangements.isEmpty && !arrangements.contains(opportunity.arrangement) {
            return false
        }

        if !modules.isEmpty && !modules.contains(opportunity.module) {
            return false
        }

        return true
    }
}

#Preview {
    FilterView(filters: .constant(JobFilters()))
}
