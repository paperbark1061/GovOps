import SwiftUI

/// Browse the skills taxonomy, see demand across opportunities, and find training paths
struct SkillsExplorerView: View {
    @EnvironmentObject var dataService: DataService
    @State private var selectedCategory: SkillCategory? = nil
    @State private var searchText = ""

    var filteredSkills: [TaxonomySkill] {
        var results = SkillsTaxonomyDB.skills
        if let cat = selectedCategory {
            results = results.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            results = results.filter {
                $0.name.lowercased().contains(query) ||
                $0.keywords.contains { $0.lowercased().contains(query) }
            }
        }
        return results
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Category pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            CategoryPill(name: "All", icon: "square.grid.2x2", isSelected: selectedCategory == nil) {
                                selectedCategory = nil
                            }

                            ForEach(SkillCategory.allCases) { category in
                                CategoryPill(
                                    name: category.rawValue.components(separatedBy: " ").first ?? category.rawValue,
                                    icon: category.icon,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = (selectedCategory == category) ? nil : category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Skills demand summary
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Skills Demand")
                            .font(.headline)
                            .padding(.horizontal)

                        Text("Based on \(dataService.opportunities.count) current BuyICT opportunities")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        LazyVStack(spacing: 0) {
                            ForEach(filteredSkills) { skill in
                                NavigationLink(destination: SkillDetailView(skill: skill)) {
                                    SkillDemandRow(skill: skill, opportunities: dataService.opportunities)
                                }
                                .buttonStyle(.plain)

                                if skill.id != filteredSkills.last?.id {
                                    Divider().padding(.horizontal)
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGray6))
            .navigationTitle("Skills & Training")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search skills, certifications...")
        }
    }
}

struct CategoryPill: View {
    let name: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
    }
}

struct SkillDemandRow: View {
    let skill: TaxonomySkill
    let opportunities: [Opportunity]

    var matchCount: Int {
        opportunities.filter { opp in
            let titleLower = opp.title.lowercased()
            return skill.keywords.contains { titleLower.contains($0.lowercased()) }
        }.count
    }

    var demandPercentage: Double {
        guard !opportunities.isEmpty else { return 0 }
        return Double(matchCount) / Double(opportunities.count) * 100
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: skill.category.icon)
                .font(.title3)
                .foregroundColor(colorForCategory(skill.category))
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(skill.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Text("\(matchCount) opportunities")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if !skill.certifications.isEmpty {
                        HStack(spacing: 2) {
                            Image(systemName: "rosette")
                                .font(.caption2)
                            Text("\(skill.certifications.count) certs")
                                .font(.caption)
                        }
                        .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            // Demand bar
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(demandPercentage))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(demandColor)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(.systemGray5))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(demandColor)
                            .frame(width: max(0, geo.size.width * demandPercentage / 100), height: 4)
                    }
                }
                .frame(width: 60, height: 4)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    var demandColor: Color {
        if demandPercentage > 30 { return .red }
        if demandPercentage > 15 { return .orange }
        if demandPercentage > 5 { return .blue }
        return .gray
    }

    func colorForCategory(_ cat: SkillCategory) -> Color {
        switch cat {
        case .strategyArchitecture: return .purple
        case .changeTransformation: return .orange
        case .developmentImplementation: return .blue
        case .deliveryOperations: return .green
        case .securityCompliance: return .red
        case .dataAnalytics: return .teal
        case .cloudInfrastructure: return .indigo
        }
    }
}

// MARK: - Skill Detail View

struct SkillDetailView: View {
    let skill: TaxonomySkill
    @EnvironmentObject var dataService: DataService

    var matchingOpportunities: [Opportunity] {
        dataService.opportunities.filter { opp in
            let titleLower = opp.title.lowercased()
            return skill.keywords.contains { titleLower.contains($0.lowercased()) }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: skill.category.icon)
                            .font(.title2)
                            .foregroundColor(.blue)

                        Text(skill.name)
                            .font(.title2)
                            .fontWeight(.bold)
                    }

                    Text(skill.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        Label(skill.category.rawValue, systemImage: "folder")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let code = skill.sfiaCode {
                            Text("SFIA: \(code)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.purple.opacity(0.1))
                                .foregroundColor(.purple)
                                .cornerRadius(4)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)

                // SFIA Levels
                if !skill.levels.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("SFIA Levels")
                            .font(.headline)

                        ForEach(skill.levels, id: \.self) { level in
                            if let sfiaLevel = SFIALevel(rawValue: level) {
                                HStack {
                                    Text("Level \(level)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(width: 56, height: 28)
                                        .background(Color.blue.opacity(Double(level) / 7.0))
                                        .cornerRadius(6)

                                    VStack(alignment: .leading) {
                                        Text(sfiaLevel.title)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text(sfiaLevel.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }

                // Certifications
                if !skill.certifications.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Certifications")
                            .font(.headline)

                        ForEach(skill.certifications) { cert in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: "rosette")
                                        .foregroundColor(.orange)
                                    Text(cert.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }

                                HStack(spacing: 12) {
                                    Label(cert.provider, systemImage: "building.2")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    if let cost = cert.estimatedCost {
                                        Label(cost, systemImage: "dollarsign.circle")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    if let hours = cert.estimatedStudyHours {
                                        Label("\(hours)h study", systemImage: "clock")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                if !cert.prerequisites.isEmpty {
                                    Text("Prerequisites: \(cert.prerequisites.joined(separator: ", "))")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }

                                if let url = cert.url, let linkURL = URL(string: url) {
                                    Link(destination: linkURL) {
                                        Label("Learn more", systemImage: "arrow.up.right.square")
                                            .font(.caption)
                                    }
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

                // Training Paths
                if !skill.trainingPaths.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Training Pathways")
                            .font(.headline)

                        ForEach(skill.trainingPaths) { path in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: "graduationcap")
                                        .foregroundColor(.blue)
                                    Text(path.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }

                                HStack(spacing: 12) {
                                    Label(path.provider, systemImage: "building")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Label(path.format.rawValue, systemImage: "desktopcomputer")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                HStack(spacing: 12) {
                                    Label(path.estimatedDuration, systemImage: "clock")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    if let cost = path.cost {
                                        Label(cost, systemImage: "dollarsign.circle")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    if let loc = path.location {
                                        Label(loc, systemImage: "mappin")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                if let url = path.url, let linkURL = URL(string: url) {
                                    Link(destination: linkURL) {
                                        Label("Visit provider", systemImage: "arrow.up.right.square")
                                            .font(.caption)
                                    }
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

                // Matching opportunities
                VStack(alignment: .leading, spacing: 10) {
                    Text("Current Opportunities (\(matchingOpportunities.count))")
                        .font(.headline)

                    if matchingOpportunities.isEmpty {
                        Text("No current BuyICT opportunities match this skill.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(matchingOpportunities.prefix(10)) { opp in
                            NavigationLink(destination: JobDetailView(opportunity: opp)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(opp.title)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .lineLimit(2)
                                            .foregroundColor(.primary)

                                        Text(opp.buyer)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Text(opp.module)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(4)
                                }
                                .padding(.vertical, 6)
                            }

                            if opp.id != matchingOpportunities.prefix(10).last?.id {
                                Divider()
                            }
                        }

                        if matchingOpportunities.count > 10 {
                            Text("+ \(matchingOpportunities.count - 10) more opportunities")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.top, 4)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
            .padding()
        }
        .background(Color(.systemGray6))
        .navigationTitle(skill.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SkillsExplorerView()
        .environmentObject(DataService.shared)
}
