import SwiftUI

/// Main tab navigation after authentication.
struct MainTabView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var dataService: DataService
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            JobListView()
                .tabItem {
                    Label("Opportunities", systemImage: "briefcase.fill")
                }
                .tag(0)

            SkillsExplorerView()
                .tabItem {
                    Label("Skills", systemImage: "graduationcap.fill")
                }
                .tag(1)

            CompanyListView()
                .tabItem {
                    Label("Companies", systemImage: "building.2.fill")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .tint(.blue)
    }
}

// MARK: - Profile View

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var dataService: DataService
    @StateObject private var profileService = UserProfileService.shared
    @State private var showSkillPicker = false
    @State private var showAddFreeSkill = false
    @State private var newFreeSkill = ""
    @State private var showLinkedInImport = false
    @State private var linkedInInput = ""

    var matchedOpportunities: [ScoredOpportunity] {
        profileService.matchingOpportunities(from: dataService.opportunities)
    }

    var body: some View {
        NavigationStack {
            List {
                // User info section
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 56, height: 56)

                            Text(authService.currentUser?.initials ?? "??")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(authService.currentUser?.name ?? "User")
                                .font(.headline)

                            Text(authService.currentUser?.email ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.caption2)
                                Text(authService.currentUser?.plan.displayName ?? "Demo")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // My Skills - SFIA
                Section {
                    if profileService.profile.sfiaSkillIds.isEmpty {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                            Text("Add your skills to get matched opportunities")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        ForEach(profileService.profile.sfiaSkillIds, id: \.self) { skillId in
                            if let skill = SkillsTaxonomyDB.skill(byId: skillId) {
                                HStack {
                                    Image(systemName: skill.category.icon)
                                        .foregroundColor(.blue)
                                        .frame(width: 24)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(skill.name)
                                            .font(.subheadline)
                                        Text(skill.category.rawValue)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .onDelete { indexSet in
                            profileService.profile.sfiaSkillIds.remove(atOffsets: indexSet)
                        }
                    }

                    Button {
                        showSkillPicker = true
                    } label: {
                        Label("Add SFIA Skill", systemImage: "plus")
                            .font(.subheadline)
                    }
                } header: {
                    Text("My Skills (SFIA)")
                }

                // Free text skills
                Section {
                    ForEach(profileService.profile.freeTextSkills, id: \.self) { skill in
                        HStack {
                            Image(systemName: "tag")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            Text(skill)
                                .font(.subheadline)
                        }
                    }
                    .onDelete { indexSet in
                        profileService.profile.freeTextSkills.remove(atOffsets: indexSet)
                    }

                    Button {
                        showAddFreeSkill = true
                    } label: {
                        Label("Add Custom Skill", systemImage: "plus")
                            .font(.subheadline)
                    }
                } header: {
                    Text("Custom Skills & Keywords")
                }

                // Preferences
                Section("Preferences") {
                    Picker("Preferred Location", selection: Binding(
                        get: { profileService.profile.preferredLocation ?? "" },
                        set: { profileService.profile.preferredLocation = $0.isEmpty ? nil : $0 }
                    )) {
                        Text("Any").tag("")
                        Text("ACT").tag("ACT")
                        Text("NSW").tag("NSW")
                        Text("VIC").tag("VIC")
                        Text("QLD").tag("QLD")
                        Text("SA").tag("SA")
                        Text("WA").tag("WA")
                        Text("TAS").tag("TAS")
                        Text("NT").tag("NT")
                    }
                    .font(.subheadline)

                    Picker("Arrangement", selection: Binding(
                        get: { profileService.profile.preferredArrangement ?? "" },
                        set: { profileService.profile.preferredArrangement = $0.isEmpty ? nil : $0 }
                    )) {
                        Text("Any").tag("")
                        Text("On-site").tag("On-site")
                        Text("Hybrid").tag("Hybrid")
                        Text("Remote").tag("Remote")
                    }
                    .font(.subheadline)

                    Picker("Security Clearance", selection: Binding(
                        get: { profileService.profile.clearanceLevel ?? "" },
                        set: { profileService.profile.clearanceLevel = $0.isEmpty ? nil : $0 }
                    )) {
                        Text("None").tag("")
                        ForEach(SecurityClearance.allCases, id: \.rawValue) { level in
                            Text(level.fullName).tag(level.rawValue)
                        }
                    }
                    .font(.subheadline)
                }

                // LinkedIn Import
                Section {
                    Button {
                        showLinkedInImport = true
                    } label: {
                        HStack {
                            Image(systemName: "link.circle.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Import from LinkedIn")
                                    .font(.subheadline)
                                Text("Paste your profile URL or summary text")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    if let url = profileService.profile.linkedInURL, !url.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("LinkedIn connected")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                } header: {
                    Text("Import")
                }

                // Matched Opportunities
                if !matchedOpportunities.isEmpty {
                    Section {
                        ForEach(matchedOpportunities.prefix(10)) { scored in
                            NavigationLink(destination: JobDetailView(opportunity: scored.opportunity)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(scored.opportunity.title)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .lineLimit(2)

                                        Text(scored.matchReasons.prefix(2).joined(separator: " | "))
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }

                                    Spacer()

                                    Text("\(scored.matchPercentage)%")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(scored.matchPercentage > 50 ? Color.green : Color.orange)
                                        .cornerRadius(8)
                                }
                            }
                        }

                        if matchedOpportunities.count > 10 {
                            Text("+ \(matchedOpportunities.count - 10) more matches")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    } header: {
                        Text("Matched Opportunities (\(matchedOpportunities.count))")
                    }
                }

                // Session & Data
                Section("Data Sources") {
                    SourceRow(name: "BuyICT", status: .active, count: "\(dataService.opportunities.count) opportunities")
                    SourceRow(name: "AusTender", status: .planned, count: "Coming soon")
                    SourceRow(name: "NSW eTendering", status: .planned, count: "Coming soon")
                    SourceRow(name: "State Portals", status: .planned, count: "8 portals planned")
                }

                // Sign out
                Section {
                    Button(action: {
                        profileService.reset()
                        authService.logout()
                    }) {
                        HStack {
                            Spacer()
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSkillPicker) {
                SFIASkillPickerView(selectedIds: $profileService.profile.sfiaSkillIds)
            }
            .alert("Add Custom Skill", isPresented: $showAddFreeSkill) {
                TextField("e.g. Terraform, SAFe, Power BI", text: $newFreeSkill)
                Button("Add") {
                    let trimmed = newFreeSkill.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty && !profileService.profile.freeTextSkills.contains(trimmed) {
                        profileService.profile.freeTextSkills.append(trimmed)
                    }
                    newFreeSkill = ""
                }
                Button("Cancel", role: .cancel) { newFreeSkill = "" }
            }
            .sheet(isPresented: $showLinkedInImport) {
                LinkedInImportView(profileService: profileService)
            }
        }
    }
}

// MARK: - SFIA Skill Picker

struct SFIASkillPickerView: View {
    @Binding var selectedIds: [String]
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""

    var filteredSkills: [TaxonomySkill] {
        if searchText.isEmpty { return SkillsTaxonomyDB.skills }
        let query = searchText.lowercased()
        return SkillsTaxonomyDB.skills.filter {
            $0.name.lowercased().contains(query) ||
            $0.keywords.contains { $0.lowercased().contains(query) }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(SkillCategory.allCases) { category in
                    let categorySkills = filteredSkills.filter { $0.category == category }
                    if !categorySkills.isEmpty {
                        Section(category.rawValue) {
                            ForEach(categorySkills) { skill in
                                Button {
                                    if selectedIds.contains(skill.id) {
                                        selectedIds.removeAll { $0 == skill.id }
                                    } else {
                                        selectedIds.append(skill.id)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: skill.category.icon)
                                            .foregroundColor(.blue)
                                            .frame(width: 24)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(skill.name)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                            Text(skill.description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }

                                        Spacer()

                                        if selectedIds.contains(skill.id) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search skills...")
            .navigationTitle("Select Skills")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - LinkedIn Import

struct LinkedInImportView: View {
    @ObservedObject var profileService: UserProfileService
    @Environment(\.dismiss) var dismiss
    @State private var inputText = ""
    @State private var extractedSkills: [TaxonomySkill] = []
    @State private var hasAnalysed = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Paste your LinkedIn profile URL or copy your profile summary/skills text below.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                TextEditor(text: $inputText)
                    .frame(minHeight: 150)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .padding(.horizontal)

                if hasAnalysed && !extractedSkills.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Skills Found")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(extractedSkills) { skill in
                            HStack {
                                Image(systemName: skill.category.icon)
                                    .foregroundColor(.blue)
                                Text(skill.name)
                                    .font(.subheadline)
                                Spacer()
                                if profileService.profile.sfiaSkillIds.contains(skill.id) {
                                    Text("Added")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                Spacer()

                if hasAnalysed && !extractedSkills.isEmpty {
                    Button {
                        for skill in extractedSkills {
                            if !profileService.profile.sfiaSkillIds.contains(skill.id) {
                                profileService.profile.sfiaSkillIds.append(skill.id)
                            }
                        }
                        if inputText.lowercased().contains("linkedin.com") {
                            profileService.profile.linkedInURL = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        dismiss()
                    } label: {
                        Text("Add \(extractedSkills.count) Skills to Profile")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                } else {
                    Button {
                        analyseInput()
                    } label: {
                        Text("Analyse")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(inputText.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(inputText.isEmpty)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .navigationTitle("LinkedIn Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func analyseInput() {
        let matched = SkillsTaxonomyDB.extractSkills(from: inputText)
        extractedSkills = matched.compactMap { SkillsTaxonomyDB.skill(byId: $0.skillId) }
        hasAnalysed = true
    }
}

// MARK: - Supporting Views

struct SourceRow: View {
    let name: String
    let status: SourceStatus
    let count: String

    enum SourceStatus {
        case active, planned, error

        var color: Color {
            switch self {
            case .active: return .green
            case .planned: return .orange
            case .error: return .red
            }
        }

        var icon: String {
            switch self {
            case .active: return "checkmark.circle.fill"
            case .planned: return "clock.fill"
            case .error: return "exclamationmark.circle.fill"
            }
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                Text(count)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: status.icon)
                .foregroundColor(status.color)
                .font(.body)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthService.shared)
        .environmentObject(DataService.shared)
}
