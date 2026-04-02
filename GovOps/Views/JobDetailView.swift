import SwiftUI

struct JobDetailView: View {
    @EnvironmentObject var dataService: DataService
    let opportunity: Opportunity

    var matchingCompanies: [Company] {
        dataService.getCompanies(forOpportunity: opportunity)
    }

    var allCompanies: [Company] {
        dataService.companies
    }

    // 3-tier matching
    var exactMatchCompanies: [Company] {
        dataService.getExactMatchCompanies(forOpportunity: opportunity)
    }

    var similarMatchCompanies: [Company] {
        dataService.getSimilarMatchCompanies(forOpportunity: opportunity)
    }

    var capableCompanies: [Company] {
        dataService.getCapableCompanies(forOpportunity: opportunity)
    }

    var extractedSkills: [TaxonomySkill] {
        let matched = SkillsTaxonomyDB.extractSkills(from: opportunity.title)
        return matched.compactMap { SkillsTaxonomyDB.skill(byId: $0.skillId) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
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

                // Details card
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(label: "Reference", value: opportunity.id)
                    Divider()
                    if !opportunity.arrangement.isEmpty {
                        DetailRow(label: "Arrangement", value: opportunity.arrangement)
                        Divider()
                    }
                    if !opportunity.location.isEmpty {
                        DetailRow(label: "Location", value: opportunity.location)
                        Divider()
                    }
                    if !opportunity.category.isEmpty {
                        DetailRow(label: "Category", value: opportunity.category)
                        Divider()
                    }
                    if !opportunity.module.isEmpty {
                        DetailRow(label: "Module", value: opportunity.module)
                        Divider()
                    }
                    if !opportunity.closing.isEmpty {
                        DetailRow(label: "Closing Date", value: opportunity.closing)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Original Advert Link - prominent
                if let url = URL(string: opportunity.effectiveBuyictURL) {
                    Link(destination: url) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("View Original Listing")
                                    .fontWeight(.semibold)
                                Text("Open on BuyICT")
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.title3)
                        }
                        .padding()
                        .background(
                            LinearGradient(colors: [Color.blue, Color.blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }

                // Skills Section - clickable to SkillDetailView
                if !extractedSkills.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "graduationcap.fill")
                                .foregroundColor(.blue)
                            Text("Required Skills")
                                .font(.headline)
                        }

                        Text("Tap a skill to see certifications and training pathways")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        FlowLayout(spacing: 8) {
                            ForEach(extractedSkills) { skill in
                                NavigationLink(destination: SkillDetailView(skill: skill)) {
                                    HStack(spacing: 6) {
                                        Image(systemName: skill.category.icon)
                                            .font(.caption2)
                                        Text(skill.name)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 8, weight: .bold))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(20)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }

                // Also show basic skill chips from title extraction
                let basicSkills = opportunity.skills.filter { basic in
                    !extractedSkills.contains { $0.name == basic }
                }
                if !basicSkills.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Additional Keywords")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        FlowLayout(spacing: 8) {
                            ForEach(basicSkills, id: \.self) { skill in
                                SkillChip(skill: skill)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                // 3-Tier Companies
                if !exactMatchCompanies.isEmpty {
                    CompanyTierSection(
                        title: "Recruiting This Role",
                        subtitle: "Companies actively advertising this or very similar roles",
                        icon: "checkmark.seal.fill",
                        iconColor: .green,
                        companies: exactMatchCompanies
                    )
                }

                if !similarMatchCompanies.isEmpty {
                    CompanyTierSection(
                        title: "Similar Roles",
                        subtitle: "Companies recruiting for roles with overlapping skills",
                        icon: "arrow.triangle.branch",
                        iconColor: .orange,
                        companies: similarMatchCompanies
                    )
                }

                if !capableCompanies.isEmpty {
                    CompanyTierSection(
                        title: "Panel Capable",
                        subtitle: "Approved panel suppliers with capability in this area",
                        icon: "building.2.fill",
                        iconColor: .blue,
                        companies: capableCompanies
                    )
                }

                Spacer()
            }
            .padding()
        }
        .background(Color(.systemGray6))
        .navigationTitle("Opportunity")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Company Tier Section

struct CompanyTierSection: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let companies: [Company]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            ForEach(companies) { company in
                NavigationLink(destination: CompanyDetailView(company: company)) {
                    CompanyMiniCard(company: company)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct CompanyMiniCard: View {
    let company: Company

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 44, height: 44)
                Text(String(company.name.prefix(2)).uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(company.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                if !company.advertisingRoles.isEmpty {
                    Text(company.advertisingRoles.prefix(2).joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if company.isAdvertising {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Supporting Views

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
