# GovOps

A SwiftUI iPhone app for tracking Australian Government ICT opportunities from [BuyICT.gov.au](https://www.buyict.gov.au).

## Features

- **127 live opportunities** from BuyICT Digital Marketplace Panel 2
- **Filter by role type** — Developer, Analyst, Tester, Architect, Engineer, Manager, Cyber, SAP, Data, UX
- **Filter by location** — ACT, NSW, VIC, QLD, WA, SA, TAS, NT
- **Filter by arrangement** — Hybrid, Remote, Onsite
- **Filter by module** — ICT Labour Hire, Professional & Consulting Services, RFI
- **Company matching** — Shows which BuyICT panel companies are actively advertising each role
- **Direct opportunity links** — Each listing links directly to the BuyICT opportunity detail page
- **Automatic skill extraction** — Tags derived from job titles using regex pattern matching
- **Color-coded modules** — Blue (Labour Hire), Green (Professional Services), Orange (RFI)
- **Pull-to-refresh** — Ready for future API integration
- **Dark mode support**

## Architecture

```
GovOps/
├── GovOpsApp.swift              # App entry point
├── Models/
│   ├── Opportunity.swift         # Job opportunity model with skill extraction
│   └── Company.swift             # Company/recruiter model
├── Views/
│   ├── JobListView.swift         # Main list with search & filter
│   ├── JobDetailView.swift       # Full opportunity details
│   ├── FilterView.swift          # Multi-category filter sheet
│   └── CompanyListView.swift     # Companies directory
├── Services/
│   └── DataService.swift         # JSON data loading singleton
└── Resources/
    ├── opportunities.json        # Opportunity data (part 1)
    ├── opportunities2.json       # Opportunity data (part 2)
    ├── opportunities3.json       # Opportunity data (part 3)
    └── companies.json            # Company data
```

## Updating Data

The app is data-driven via JSON files. To refresh:

1. Re-run the BuyICT scraping process
2. Replace the `Resources/*.json` files with the new data
3. Build and run — the app automatically loads the updated data

## Data Sources

- **Opportunities**: [BuyICT Opportunities](https://www.buyict.gov.au/public?id=opportunities&topic_id=292278ac1bf62a50f421db96b04bcbd5)
- **Seller Catalogue**: [BuyICT Sellers](https://www.buyict.gov.au/public?id=seller_catalogue&topic_id=4cd374601b3a2a50f421db96b04bcbc5)
- **Company Research**: Seek.com.au, LinkedIn, Indeed — cross-referenced against 2,786 BuyICT panel sellers

## Requirements

- Xcode 15+
- iOS 17.0+
- Swift 5.9+

## Setup

1. Clone this repo
2. Open `GovOps.xcodeproj` in Xcode
3. Build and run

## License

MIT
