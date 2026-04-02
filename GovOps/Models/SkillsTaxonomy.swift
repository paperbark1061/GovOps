import Foundation

// MARK: - SFIA-Based Skills Taxonomy

/// Top-level skill category aligned with SFIA framework
enum SkillCategory: String, Codable, CaseIterable, Identifiable {
    case strategyArchitecture = "Strategy & Architecture"
    case changeTransformation = "Change & Transformation"
    case developmentImplementation = "Development & Implementation"
    case deliveryOperations = "Delivery & Operations"
    case securityCompliance = "Security & Compliance"
    case dataAnalytics = "Data & Analytics"
    case cloudInfrastructure = "Cloud & Infrastructure"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .strategyArchitecture: return "map"
        case .changeTransformation: return "arrow.triangle.2.circlepath"
        case .developmentImplementation: return "chevron.left.forwardslash.chevron.right"
        case .deliveryOperations: return "gearshape.2"
        case .securityCompliance: return "lock.shield"
        case .dataAnalytics: return "chart.bar.xaxis"
        case .cloudInfrastructure: return "cloud"
        }
    }

    var color: String {
        switch self {
        case .strategyArchitecture: return "purple"
        case .changeTransformation: return "orange"
        case .developmentImplementation: return "blue"
        case .deliveryOperations: return "green"
        case .securityCompliance: return "red"
        case .dataAnalytics: return "teal"
        case .cloudInfrastructure: return "indigo"
        }
    }
}

/// SFIA responsibility level (1-7)
enum SFIALevel: Int, Codable, CaseIterable, Comparable {
    case follow = 1
    case assist = 2
    case apply = 3
    case enable = 4
    case ensure = 5
    case initiate = 6
    case setStrategy = 7

    static func < (lhs: SFIALevel, rhs: SFIALevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var title: String {
        switch self {
        case .follow: return "Follow"
        case .assist: return "Assist"
        case .apply: return "Apply"
        case .enable: return "Enable"
        case .ensure: return "Ensure"
        case .initiate: return "Initiate"
        case .setStrategy: return "Set Strategy"
        }
    }

    var description: String {
        switch self {
        case .follow: return "Works under close supervision"
        case .assist: return "Works under routine direction"
        case .apply: return "Works under general direction"
        case .enable: return "Accountable for team outcomes"
        case .ensure: return "Ensures organisational capability"
        case .initiate: return "Initiates and influences strategy"
        case .setStrategy: return "Sets organisational strategy"
        }
    }
}

/// A specific skill or competency within the taxonomy
struct TaxonomySkill: Identifiable, Codable {
    let id: String               // e.g. "PROG" for Programming/Software Development
    let name: String             // e.g. "Software Development"
    let category: SkillCategory
    let sfiaCode: String?        // Official SFIA code if applicable
    let description: String
    let levels: [Int]            // Which SFIA levels this skill applies at (e.g. [2,3,4,5])
    let keywords: [String]       // Keywords to match in tender descriptions
    let certifications: [Certification]
    let trainingPaths: [TrainingPath]
}

/// A formal certification or accreditation
struct Certification: Identifiable, Codable {
    let id: String
    let name: String             // e.g. "AWS Solutions Architect Associate"
    let provider: String         // e.g. "Amazon Web Services"
    let type: CertificationType
    let url: String?
    let estimatedCost: String?   // e.g. "$300 USD"
    let estimatedStudyHours: Int?
    let prerequisites: [String]
    let renewalPeriod: String?   // e.g. "3 years"
}

enum CertificationType: String, Codable {
    case vendor = "Vendor"
    case industry = "Industry"
    case government = "Government"
    case academic = "Academic"
}

/// A training pathway to acquire a skill
struct TrainingPath: Identifiable, Codable {
    let id: String
    let name: String             // e.g. "AWS Cloud Practitioner to SA Associate"
    let provider: String         // e.g. "A Cloud Guru"
    let providerType: ProviderType
    let url: String?
    let format: TrainingFormat
    let estimatedDuration: String // e.g. "40 hours", "6 months"
    let cost: String?
    let location: String?        // "Online", "Canberra", etc.
}

enum ProviderType: String, Codable {
    case university = "University"
    case tafe = "TAFE"
    case onlinePlatform = "Online Platform"
    case vendorTraining = "Vendor Training"
    case bootcamp = "Bootcamp"
    case professional = "Professional Body"
}

enum TrainingFormat: String, Codable {
    case online = "Online"
    case inPerson = "In Person"
    case hybrid = "Hybrid"
    case selfPaced = "Self-Paced"
}

// MARK: - Security Clearances

enum SecurityClearance: String, Codable, CaseIterable, Comparable {
    case baseline = "Baseline"
    case nv1 = "NV1"
    case nv2 = "NV2"
    case pv = "PV"

    static func < (lhs: SecurityClearance, rhs: SecurityClearance) -> Bool {
        let order: [SecurityClearance] = [.baseline, .nv1, .nv2, .pv]
        return (order.firstIndex(of: lhs) ?? 0) < (order.firstIndex(of: rhs) ?? 0)
    }

    var fullName: String {
        switch self {
        case .baseline: return "Baseline Vetting"
        case .nv1: return "Negative Vetting Level 1"
        case .nv2: return "Negative Vetting Level 2"
        case .pv: return "Positive Vetting"
        }
    }

    var processingTime: String {
        switch self {
        case .baseline: return "1-3 months"
        case .nv1: return "3-6 months"
        case .nv2: return "6-12 months"
        case .pv: return "12+ months"
        }
    }

    var description: String {
        switch self {
        case .baseline: return "Access to PROTECTED information"
        case .nv1: return "Access to SECRET information"
        case .nv2: return "Access to TOP SECRET information"
        case .pv: return "Access to codeword and compartmented information"
        }
    }
}

// MARK: - Extracted Requirements from a Tender

/// Structured requirements extracted from a tender or job listing
struct ExtractedRequirements: Codable {
    let skills: [MatchedSkill]
    let certifications: [String]
    let clearance: SecurityClearance?
    let experience: ExperienceRequirement?
    let qualifications: [String]
}

struct MatchedSkill: Codable, Identifiable {
    var id: String { skillId }
    let skillId: String          // References TaxonomySkill.id
    let confidence: Double       // 0.0-1.0 matching confidence
    let matchedKeyword: String   // The keyword that triggered the match
    let suggestedLevel: Int?     // Suggested SFIA level based on context
}

struct ExperienceRequirement: Codable {
    let minimumYears: Int?
    let preferredYears: Int?
    let domain: String?          // e.g. "government", "defence", "healthcare"
}

// MARK: - Skills Taxonomy Database

/// Static taxonomy database with built-in skills, certs, and training paths
struct SkillsTaxonomyDB {

    static let skills: [TaxonomySkill] = [
        // Strategy & Architecture
        TaxonomySkill(
            id: "ARCH", name: "Solution Architecture", category: .strategyArchitecture,
            sfiaCode: "ARCH", description: "Design and communication of high-level solution structures",
            levels: [4, 5, 6],
            keywords: ["architect", "solution design", "enterprise architecture", "technical architecture", "systems design"],
            certifications: [
                Certification(id: "togaf", name: "TOGAF 10 Certified", provider: "The Open Group",
                             type: .industry, url: "https://www.opengroup.org/togaf", estimatedCost: "$500 USD",
                             estimatedStudyHours: 80, prerequisites: [], renewalPeriod: nil)
            ],
            trainingPaths: [
                TrainingPath(id: "togaf-train", name: "TOGAF 10 Training", provider: "Lumify Work",
                            providerType: .professional, url: "https://www.lumifywork.com", format: .hybrid,
                            estimatedDuration: "5 days", cost: "$4,500 AUD", location: "Canberra, Sydney, Online")
            ]
        ),

        // Development & Implementation
        TaxonomySkill(
            id: "PROG", name: "Software Development", category: .developmentImplementation,
            sfiaCode: "PROG", description: "Design, creation, testing and documentation of software",
            levels: [2, 3, 4, 5],
            keywords: ["developer", "software", "programming", "coding", ".net", "java", "python", "full stack", "frontend", "backend"],
            certifications: [
                Certification(id: "az204", name: "Azure Developer Associate", provider: "Microsoft",
                             type: .vendor, url: "https://learn.microsoft.com/en-us/certifications/azure-developer/",
                             estimatedCost: "$230 AUD", estimatedStudyHours: 60, prerequisites: [], renewalPeriod: "1 year"),
                Certification(id: "aws-dev", name: "AWS Developer Associate", provider: "Amazon Web Services",
                             type: .vendor, url: "https://aws.amazon.com/certification/certified-developer-associate/",
                             estimatedCost: "$225 AUD", estimatedStudyHours: 50, prerequisites: [], renewalPeriod: "3 years")
            ],
            trainingPaths: [
                TrainingPath(id: "acg-dev", name: "AWS Developer Learning Path", provider: "A Cloud Guru",
                            providerType: .onlinePlatform, url: "https://acloudguru.com", format: .selfPaced,
                            estimatedDuration: "40 hours", cost: "$49/month", location: "Online")
            ]
        ),

        TaxonomySkill(
            id: "TEST", name: "Testing", category: .developmentImplementation,
            sfiaCode: "TEST", description: "Planning, design, management, execution and reporting of tests",
            levels: [2, 3, 4, 5],
            keywords: ["test", "testing", "qa", "quality assurance", "automation", "selenium", "test analyst"],
            certifications: [
                Certification(id: "istqb", name: "ISTQB Foundation Level", provider: "ISTQB",
                             type: .industry, url: "https://www.istqb.org", estimatedCost: "$300 AUD",
                             estimatedStudyHours: 30, prerequisites: [], renewalPeriod: nil)
            ],
            trainingPaths: [
                TrainingPath(id: "istqb-train", name: "ISTQB Foundation Training", provider: "Planit",
                            providerType: .professional, url: "https://www.planit.com", format: .hybrid,
                            estimatedDuration: "3 days", cost: "$2,200 AUD", location: "All capitals")
            ]
        ),

        // Security & Compliance
        TaxonomySkill(
            id: "SCTY", name: "Cyber Security", category: .securityCompliance,
            sfiaCode: "SCTY", description: "Management of security across information systems",
            levels: [3, 4, 5, 6],
            keywords: ["cyber", "security", "infosec", "information security", "soc", "incident response", "threat", "vulnerability", "penetration"],
            certifications: [
                Certification(id: "cissp", name: "CISSP", provider: "ISC2",
                             type: .industry, url: "https://www.isc2.org/certifications/cissp",
                             estimatedCost: "$1,000 AUD", estimatedStudyHours: 120,
                             prerequisites: ["5 years security experience"], renewalPeriod: "3 years"),
                Certification(id: "secplus", name: "CompTIA Security+", provider: "CompTIA",
                             type: .industry, url: "https://www.comptia.org/certifications/security",
                             estimatedCost: "$550 AUD", estimatedStudyHours: 60, prerequisites: [], renewalPeriod: "3 years"),
                Certification(id: "cism", name: "CISM", provider: "ISACA",
                             type: .industry, url: "https://www.isaca.org/credentialing/cism",
                             estimatedCost: "$900 AUD", estimatedStudyHours: 100,
                             prerequisites: ["5 years IS management"], renewalPeriod: "3 years")
            ],
            trainingPaths: [
                TrainingPath(id: "tafe-cyber", name: "Certificate IV in Cyber Security", provider: "TAFE",
                            providerType: .tafe, url: "https://www.tafensw.edu.au", format: .hybrid,
                            estimatedDuration: "6-12 months", cost: "Subsidised", location: "All states"),
                TrainingPath(id: "sans-train", name: "SANS Cyber Security Training", provider: "SANS Institute",
                            providerType: .professional, url: "https://www.sans.org", format: .hybrid,
                            estimatedDuration: "6 days per course", cost: "$8,000+ AUD", location: "Canberra, Sydney, Online")
            ]
        ),

        // Cloud & Infrastructure
        TaxonomySkill(
            id: "CLDP", name: "Cloud Platform", category: .cloudInfrastructure,
            sfiaCode: nil, description: "Design, deployment and management of cloud services and platforms",
            levels: [3, 4, 5, 6],
            keywords: ["cloud", "aws", "azure", "gcp", "openstack", "iaas", "paas", "saas", "migration"],
            certifications: [
                Certification(id: "aws-saa", name: "AWS Solutions Architect Associate", provider: "Amazon Web Services",
                             type: .vendor, url: "https://aws.amazon.com/certification/certified-solutions-architect-associate/",
                             estimatedCost: "$225 AUD", estimatedStudyHours: 60, prerequisites: [], renewalPeriod: "3 years"),
                Certification(id: "az104", name: "Azure Administrator Associate", provider: "Microsoft",
                             type: .vendor, url: "https://learn.microsoft.com/en-us/certifications/azure-administrator/",
                             estimatedCost: "$230 AUD", estimatedStudyHours: 50, prerequisites: [], renewalPeriod: "1 year"),
                Certification(id: "gcp-ace", name: "Google Cloud Associate Cloud Engineer", provider: "Google",
                             type: .vendor, url: "https://cloud.google.com/certification/cloud-engineer",
                             estimatedCost: "$300 USD", estimatedStudyHours: 50, prerequisites: [], renewalPeriod: "2 years")
            ],
            trainingPaths: [
                TrainingPath(id: "acg-aws", name: "AWS Certified Solutions Architect Path", provider: "A Cloud Guru",
                            providerType: .onlinePlatform, url: "https://acloudguru.com", format: .selfPaced,
                            estimatedDuration: "50 hours", cost: "$49/month", location: "Online"),
                TrainingPath(id: "ms-learn", name: "Microsoft Learn: Azure Fundamentals to Admin", provider: "Microsoft",
                            providerType: .vendorTraining, url: "https://learn.microsoft.com", format: .selfPaced,
                            estimatedDuration: "40 hours", cost: "Free", location: "Online")
            ]
        ),

        TaxonomySkill(
            id: "ITOP", name: "Infrastructure Operations", category: .cloudInfrastructure,
            sfiaCode: "ITOP", description: "Operation and control of IT infrastructure",
            levels: [1, 2, 3, 4, 5],
            keywords: ["infrastructure", "sysadmin", "windows", "linux", "unix", "vmware", "network", "server", "storage"],
            certifications: [
                Certification(id: "rhcsa", name: "Red Hat Certified System Administrator", provider: "Red Hat",
                             type: .vendor, url: "https://www.redhat.com/en/services/certification/rhcsa",
                             estimatedCost: "$600 AUD", estimatedStudyHours: 80, prerequisites: [], renewalPeriod: "3 years")
            ],
            trainingPaths: [
                TrainingPath(id: "tafe-it", name: "Certificate IV in Information Technology", provider: "TAFE",
                            providerType: .tafe, url: "https://www.tafensw.edu.au", format: .hybrid,
                            estimatedDuration: "12 months", cost: "Subsidised", location: "All states")
            ]
        ),

        // Change & Transformation
        TaxonomySkill(
            id: "PRMG", name: "Project Management", category: .changeTransformation,
            sfiaCode: "PRMG", description: "Management of projects achieving defined objectives",
            levels: [4, 5, 6],
            keywords: ["project manager", "project management", "pmp", "prince2", "scrum", "agile", "delivery manager", "program"],
            certifications: [
                Certification(id: "prince2f", name: "PRINCE2 Foundation", provider: "PeopleCert/Axelos",
                             type: .industry, url: "https://www.axelos.com/certifications/prince2",
                             estimatedCost: "$600 AUD", estimatedStudyHours: 30, prerequisites: [], renewalPeriod: nil),
                Certification(id: "prince2p", name: "PRINCE2 Practitioner", provider: "PeopleCert/Axelos",
                             type: .industry, url: "https://www.axelos.com/certifications/prince2",
                             estimatedCost: "$800 AUD", estimatedStudyHours: 40,
                             prerequisites: ["PRINCE2 Foundation"], renewalPeriod: "3 years"),
                Certification(id: "pmp", name: "PMP", provider: "PMI",
                             type: .industry, url: "https://www.pmi.org/certifications/project-management-pmp",
                             estimatedCost: "$800 AUD", estimatedStudyHours: 100,
                             prerequisites: ["3-5 years project management experience"], renewalPeriod: "3 years"),
                Certification(id: "csm", name: "Certified ScrumMaster", provider: "Scrum Alliance",
                             type: .industry, url: "https://www.scrumalliance.org/get-certified/scrum-master-track/certified-scrummaster",
                             estimatedCost: "$1,500 AUD", estimatedStudyHours: 16, prerequisites: [], renewalPeriod: "2 years")
            ],
            trainingPaths: [
                TrainingPath(id: "lumify-pm", name: "PRINCE2 Foundation + Practitioner", provider: "Lumify Work",
                            providerType: .professional, url: "https://www.lumifywork.com", format: .hybrid,
                            estimatedDuration: "5 days", cost: "$4,500 AUD", location: "Canberra, Sydney, Melbourne, Online")
            ]
        ),

        // Data & Analytics
        TaxonomySkill(
            id: "DTAN", name: "Data Analytics", category: .dataAnalytics,
            sfiaCode: "DTAN", description: "Analysis of data to derive insights and support decision-making",
            levels: [3, 4, 5, 6],
            keywords: ["data", "analytics", "bi", "business intelligence", "power bi", "tableau", "reporting", "data warehouse", "etl"],
            certifications: [
                Certification(id: "dp900", name: "Azure Data Fundamentals", provider: "Microsoft",
                             type: .vendor, url: "https://learn.microsoft.com/en-us/certifications/azure-data-fundamentals/",
                             estimatedCost: "$230 AUD", estimatedStudyHours: 20, prerequisites: [], renewalPeriod: nil),
                Certification(id: "pbi", name: "Power BI Data Analyst Associate", provider: "Microsoft",
                             type: .vendor, url: "https://learn.microsoft.com/en-us/certifications/power-bi-data-analyst-associate/",
                             estimatedCost: "$230 AUD", estimatedStudyHours: 40, prerequisites: [], renewalPeriod: "1 year")
            ],
            trainingPaths: [
                TrainingPath(id: "coursera-da", name: "Google Data Analytics Certificate", provider: "Coursera",
                            providerType: .onlinePlatform, url: "https://www.coursera.org", format: .selfPaced,
                            estimatedDuration: "6 months", cost: "$59/month", location: "Online")
            ]
        ),

        TaxonomySkill(
            id: "SAPK", name: "SAP", category: .developmentImplementation,
            sfiaCode: nil, description: "Implementation, configuration and support of SAP enterprise systems",
            levels: [3, 4, 5, 6],
            keywords: ["sap", "s/4hana", "sap hana", "abap", "sap basis", "sap fi", "sap mm", "sap hr"],
            certifications: [
                Certification(id: "sap-assoc", name: "SAP Certified Associate", provider: "SAP",
                             type: .vendor, url: "https://training.sap.com/certification",
                             estimatedCost: "$600 AUD", estimatedStudyHours: 80, prerequisites: [], renewalPeriod: nil)
            ],
            trainingPaths: [
                TrainingPath(id: "sap-learn", name: "SAP Learning Hub", provider: "SAP",
                            providerType: .vendorTraining, url: "https://learning.sap.com", format: .selfPaced,
                            estimatedDuration: "Variable", cost: "$300/year", location: "Online")
            ]
        ),

        // Delivery & Operations
        TaxonomySkill(
            id: "SLMO", name: "IT Service Management", category: .deliveryOperations,
            sfiaCode: "SLMO", description: "Management of IT services to meet business needs",
            levels: [3, 4, 5, 6],
            keywords: ["itil", "service management", "itsm", "service desk", "incident management", "servicenow", "change management"],
            certifications: [
                Certification(id: "itil4f", name: "ITIL 4 Foundation", provider: "PeopleCert/Axelos",
                             type: .industry, url: "https://www.axelos.com/certifications/itil-service-management/itil-4-foundation",
                             estimatedCost: "$600 AUD", estimatedStudyHours: 20, prerequisites: [], renewalPeriod: nil),
                Certification(id: "snow-csa", name: "ServiceNow Certified System Administrator", provider: "ServiceNow",
                             type: .vendor, url: "https://www.servicenow.com/services/training-and-certification.html",
                             estimatedCost: "Free exam", estimatedStudyHours: 40, prerequisites: [], renewalPeriod: "Annual")
            ],
            trainingPaths: [
                TrainingPath(id: "lumify-itil", name: "ITIL 4 Foundation Training", provider: "Lumify Work",
                            providerType: .professional, url: "https://www.lumifywork.com", format: .hybrid,
                            estimatedDuration: "3 days", cost: "$2,500 AUD", location: "All capitals, Online")
            ]
        ),

        TaxonomySkill(
            id: "DVOP", name: "DevOps", category: .deliveryOperations,
            sfiaCode: nil, description: "Practices combining software development and IT operations",
            levels: [3, 4, 5],
            keywords: ["devops", "ci/cd", "pipeline", "deployment", "containerization", "docker", "kubernetes", "terraform", "ansible"],
            certifications: [
                Certification(id: "cka", name: "Certified Kubernetes Administrator", provider: "CNCF",
                             type: .industry, url: "https://www.cncf.io/certification/cka/",
                             estimatedCost: "$500 AUD", estimatedStudyHours: 60, prerequisites: [], renewalPeriod: "3 years"),
                Certification(id: "aws-devops", name: "AWS DevOps Engineer Professional", provider: "Amazon Web Services",
                             type: .vendor, url: "https://aws.amazon.com/certification/certified-devops-engineer-professional/",
                             estimatedCost: "$450 AUD", estimatedStudyHours: 80, prerequisites: ["AWS Associate cert"], renewalPeriod: "3 years")
            ],
            trainingPaths: [
                TrainingPath(id: "acg-devops", name: "DevOps Learning Path", provider: "A Cloud Guru",
                            providerType: .onlinePlatform, url: "https://acloudguru.com", format: .selfPaced,
                            estimatedDuration: "60 hours", cost: "$49/month", location: "Online")
            ]
        ),

        // Strategy (UX)
        TaxonomySkill(
            id: "HCEV", name: "User Experience Design", category: .strategyArchitecture,
            sfiaCode: "HCEV", description: "Design of user-centred digital services and interfaces",
            levels: [3, 4, 5, 6],
            keywords: ["ux", "user experience", "ui design", "design", "frontend", "accessibility", "usability", "service design", "figma"],
            certifications: [
                Certification(id: "gux", name: "Google UX Design Certificate", provider: "Google/Coursera",
                             type: .vendor, url: "https://www.coursera.org/professional-certificates/google-ux-design",
                             estimatedCost: "$59/month", estimatedStudyHours: 150, prerequisites: [], renewalPeriod: nil)
            ],
            trainingPaths: [
                TrainingPath(id: "ga-ux", name: "UX Design Immersive", provider: "General Assembly",
                            providerType: .bootcamp, url: "https://generalassemb.ly", format: .hybrid,
                            estimatedDuration: "12 weeks", cost: "$16,000 AUD", location: "Sydney, Melbourne, Online")
            ]
        ),

        TaxonomySkill(
            id: "BUAN", name: "Business Analysis", category: .strategyArchitecture,
            sfiaCode: "BUAN", description: "Investigation and analysis of business needs and requirements",
            levels: [3, 4, 5, 6],
            keywords: ["business analyst", "business analysis", "requirements", "stakeholder", "process mapping", "brd"],
            certifications: [
                Certification(id: "cbap", name: "CBAP", provider: "IIBA",
                             type: .industry, url: "https://www.iiba.org/business-analysis-certifications/cbap/",
                             estimatedCost: "$500 AUD", estimatedStudyHours: 80,
                             prerequisites: ["7,500 hours BA experience"], renewalPeriod: "3 years")
            ],
            trainingPaths: []
        ),

        TaxonomySkill(
            id: "DBAD", name: "Database Administration", category: .dataAnalytics,
            sfiaCode: "DBAD", description: "Installation, configuration, and management of databases",
            levels: [2, 3, 4, 5],
            keywords: ["oracle", "plsql", "pl/sql", "database", "dba", "sql server", "postgresql", "mysql", "nosql", "mongodb"],
            certifications: [
                Certification(id: "oca", name: "Oracle Database Certified Associate", provider: "Oracle",
                             type: .vendor, url: "https://education.oracle.com", estimatedCost: "$350 AUD",
                             estimatedStudyHours: 50, prerequisites: [], renewalPeriod: nil)
            ],
            trainingPaths: []
        )
    ]

    /// Find matching skills for a given text (title, description, etc.)
    static func extractSkills(from text: String) -> [MatchedSkill] {
        let textLower = text.lowercased()
        var matches: [MatchedSkill] = []

        for skill in skills {
            for keyword in skill.keywords {
                if textLower.contains(keyword.lowercased()) {
                    let confidence = keyword.count > 4 ? 0.85 : 0.65
                    matches.append(MatchedSkill(
                        skillId: skill.id,
                        confidence: confidence,
                        matchedKeyword: keyword,
                        suggestedLevel: nil
                    ))
                    break // One match per skill is enough
                }
            }
        }

        return matches.sorted { $0.confidence > $1.confidence }
    }

    /// Get skill by ID
    static func skill(byId id: String) -> TaxonomySkill? {
        skills.first { $0.id == id }
    }

    /// Get all skills in a category
    static func skills(inCategory category: SkillCategory) -> [TaxonomySkill] {
        skills.filter { $0.category == category }
    }

    /// Extract security clearance requirements from text
    static func extractClearance(from text: String) -> SecurityClearance? {
        let textLower = text.lowercased()
        if textLower.contains("positive vetting") || textLower.contains(" pv ") { return .pv }
        if textLower.contains("nv2") || textLower.contains("negative vetting level 2") || textLower.contains("top secret") { return .nv2 }
        if textLower.contains("nv1") || textLower.contains("negative vetting level 1") || textLower.contains("secret") { return .nv1 }
        if textLower.contains("baseline") || textLower.contains("security clearance") || textLower.contains("protected") { return .baseline }
        return nil
    }
}