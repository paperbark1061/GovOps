import SwiftUI

struct JobDetailView: View {
    @EnvironmentObject var dataService: DataService
    let opportunity: Opportunity

    var matchingCompanies: [Company] {
        dataService.getCompanies(forOpportunity: opportunity)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(opportunity.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .lineLimit(3)

                        Spacer()

                        ModuleBadge(module: opportunity.module)
                    }

                    Text(opportunity.buyer)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)

                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(label: "Reference", value: opportunity.id)
                    Divider()
                    DetailRow(label: "Arrangement", value: opportunity.arrangement)
                    Divider()
                    DetailRow(label: "Location", value: opportunity.location)
                    Divider()
                    DetailRow(label: "Category", value: opportunity.category)
                    Divider()
                    DetailRow(label: "Module", value: opportunity.module)
                    Divider()
                    DetailRow(label: "Closing Date", value: opportunity.closing)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                if let url = URL(string: opportunity.effectiveBuyictURL) {
                    Link(destination: url) {
                        HStack {
                            Image(systemName: "globe")
                            Text("View on BuyICT")
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                        }
                        .font(.subheadline)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                    }
                }

                if !opportunity.skills.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Key Skills")
                            .font(.headline)

                        FlowLayout(spacing: 8) {
                            ForEach(opportunity.skills, id: \.self) { skill in
                                SkillChip(skill: skill)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                if !matchingCompanies.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Companies Advertising This Role")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(matchingCompanies) { company in
                            CompanyCard(company: company)
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Job Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct ModuleBadge: View {
    let module: String

    var color: Color {
        switch module.lowercased() {
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
        Text(module)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(6)
    }
}

struct SkillChip: View {
    let skill: String

    var body: some View {
        Text(skill)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(16)
    }
}

struct CompanyCard: View {
    let company: Company

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(company.name)
                        .font(.headline)

                    if !company.advertisingRoles.isEmpty {
                        Text(company.advertisingRoles.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if company.isAdvertising {
                    Label("Active", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }

            if !company.platforms.isEmpty {
                HStack(spacing: 8) {
                    Text("Platforms:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    FlowLayout(spacing: 4) {
                        ForEach(company.platforms, id: \.self) { platform in
                            Text(platform)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
            }

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
                        Label("BuyICT Profile", systemImage: "building.columns")
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                                  proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
            totalHeight = currentY + lineHeight
        }

        return (CGSize(width: totalWidth, height: totalHeight), positions)
    }
}

#Preview {
    let sampleOpportunity = Opportunity(
        id: "LH-05460",
        title: ".NET Developer - Senior Cloud Infrastructure",
        buyer: "Department of Home Affairs",
        arrangement: "Hybrid",
        location: "ACT",
        closing: "2026-04-30",
        module: "ICT Labour Hire",
        category: "Development",
        buyictURL: "https://www.buyict.gov.au/public?id=opportunity_details&table=u_lh_procurement&sys_id=abc123&entry=opp_page"
    )

    return NavigationStack {
        JobDetailView(opportunity: sampleOpportunity)
            .environmentObject(DataService.shared)
    }
}