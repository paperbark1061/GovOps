import SwiftUI

struct CompanyDetailView: View {
    @EnvironmentObject var dataService: DataService
    let company: Company

    var linkedOpportunities: [Opportunity] {
        dataService.opportunities.filter { opp in
            dataService.getCompanies(forOpportunity: opp).contains { $0.id == company.id }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Company Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 64, height: 64)
                            Text(String(company.name.prefix(2)).uppercased())
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(company.name)
                                .font(.title2)
                                .fontWeight(.bold)

                            if let hq = company.headquarters, !hq.isEmpty {
                                Label(hq, systemImage: "mappin.circle.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: 8) {
                                if company.isAdvertising {
                                    Label("Active", systemImage: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                if let abn = company.abn, !abn.isEmpty {
                                    Text("ABN: \(abn)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    if let desc = company.description, !desc.isEmpty {
                        Text(desc)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)

                // Links
                HStack(spacing: 12) {
                    if let urlString = company.websiteURL, let url = URL(string: urlString) {
                        Link(destination: url) {
                            LinkButton(icon: "globe", label: "Website")
                        }
                    }
                    if let urlString = company.jobsURL, let url = URL(string: urlString) {
                        Link(destination: url) {
                            LinkButton(icon: "briefcase.fill", label: "Careers")
                        }
                    }
                    if let urlString = company.buyictURL, let url = URL(string: urlString) {
                        Link(destination: url) {
                            LinkButton(icon: "building.columns.fill", label: "BuyICT")
                        }
                    }
                }

                // Specialties
                if let specialties = company.specialties, !specialties.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Specialties")
                            .font(.headline)

                        FlowLayout(spacing: 8) {
                            ForEach(specialties, id: \.self) { specialty in
                                Text(specialty)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.purple.opacity(0.1))
                                    .foregroundColor(.purple)
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }

                // Panel Memberships
                if let panels = company.panels, !panels.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.green)
                            Text("Panel Memberships")
                                .font(.headline)
                        }

                        ForEach(panels) { panel in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(panel.panelName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    HStack(spacing: 8) {
                                        Label(panel.category, systemImage: "tag")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Label(panel.jurisdiction, systemImage: "mappin")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                if panel.isActive {
                                    Text("Active")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }

                // Platforms
                if !company.platforms.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recruiting Platforms")
                            .font(.headline)

                        FlowLayout(spacing: 8) {
                            ForEach(company.platforms, id: \.self) { platform in
                                Text(platform)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.teal.opacity(0.1))
                                    .foregroundColor(.teal)
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }

                // Active Opportunities
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "briefcase.fill")
                            .foregroundColor(.blue)
                        Text("Current Opportunities (\(linkedOpportunities.count))")
                            .font(.headline)
                    }

                    if linkedOpportunities.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.title2)
                                .foregroundColor(.gray)
                            Text("No current opportunities linked to this company")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    } else {
                        ForEach(linkedOpportunities.prefix(15)) { opp in
                            NavigationLink(destination: JobDetailView(opportunity: opp)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(opp.title)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .lineLimit(2)
                                            .foregroundColor(.primary)

                                        HStack(spacing: 8) {
                                            Text(opp.buyer)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            if !opp.closing.isEmpty {
                                                Text("Closes: \(opp.closing)")
                                                    .font(.caption)
                                                    .foregroundColor(.orange)
                                            }
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)

                            if opp.id != linkedOpportunities.prefix(15).last?.id {
                                Divider()
                            }
                        }

                        if linkedOpportunities.count > 15 {
                            Text("+ \(linkedOpportunities.count - 15) more opportunities")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.top, 4)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)

                Spacer()
            }
            .padding()
        }
        .background(Color(.systemGray6))
        .navigationTitle(company.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LinkButton: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .foregroundColor(.blue)
        .cornerRadius(12)
    }
}

// FlowLayout is defined in JobDetailView.swift

#Preview {
    // Note: Company data requires proper initialization matching the Company model.
    // Replace with actual sample data or use JSON decoding from sample fixtures.
    return NavigationStack {
        Text("CompanyDetailView Preview")
            .environmentObject(DataService.shared)
    }
}
