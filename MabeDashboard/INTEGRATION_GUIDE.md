# CSC-RH × NexusHR — Integration Guide for IDE Agent

## Context

You are integrating two Swift/SwiftUI macOS app branches into a single working application:

- **Backend branch** (`backend/`): SwiftData models, FoundationModels agent pipeline, RAG with CryptoKit, PDF indexing. Entry point: `CSCTestApp.swift`.
- **Frontend branch** (`frontend/`): SwiftUI dashboard (NexusHR), MVVM + Combine, Swift Charts. Entry point: `NexusHRApp.swift`.

The integration strategy is: **keep all frontend views and ViewModels untouched**. The only connection point is replacing `MockDashboardService` with `LiveDashboardService` in the frontend, which reads from the backend's SwiftData models.

---

## Prerequisites — Verify Before Starting

Before making any changes, confirm the following:

1. Both branches are checked out and buildable independently.
2. Xcode minimum deployment target is **macOS 14.0** on both targets.
3. The frontend project builds with `MockDashboardService` without errors.
4. The backend project builds without errors.
5. `FoundationModels` is imported and compiles (even if Apple Intelligence is not yet active).

If any of these fail, stop and report the error before proceeding.

---

## Step 1 — Create a Unified Xcode Project

The goal is a single `.xcodeproj` with both branches' files under one target.

**1.1** Create a new macOS App project in Xcode:
- Product Name: `NexusHR`
- Bundle Identifier: `com.mabe.nexushr`
- Minimum Deployment: macOS 14.0
- Language: Swift
- Interface: SwiftUI

**1.2** Delete the auto-generated `ContentView.swift` and `NexusHRApp.swift`.

**1.3** Drag all files from the **frontend branch** into the project navigator, preserving folder structure. Mark: ✅ Copy items if needed, ✅ Add to target: NexusHR.

**1.4** Drag all files from the **backend branch** into the project navigator. Mark the same options. **Exception**: do NOT copy `CSCTestApp.swift` — the entry point will be `NexusHRApp.swift` from the frontend.

**1.5** Add the 10 PDF files from `backend/PDFs/` to the project. In Build Phases → Copy Bundle Resources, verify all 10 PDFs appear.

**1.6** In Signing & Capabilities → App Sandbox, enable:
- ✅ User Selected File (Read Only)

---

## Step 2 — Resolve Naming Conflicts

After merging files, there will be duplicate or conflicting type names. Resolve each one:

### 2.1 Entry Point
Only one `@main` struct is allowed. Delete `CSCTestApp.swift` from the project. `NexusHRApp.swift` is the entry point.

### 2.2 Verify no duplicate model names
Search the project for duplicate `struct` or `class` definitions of:
- `ConversacionLog` — must exist only in `ConversacionLog.swift` (backend)
- `Colaborador` — must exist only in `Colaborador.swift` (backend)
- `Ticket` — must exist only in `Ticket.swift` (backend)
- `DocumentChunk` — must exist only in `DocumentChunk.swift` (backend)
- `RutaAgente` — must exist only in `RouterMockup.swift` (backend)
- `ClusterMockup` — must exist only in `ClusterMockup.swift` (backend)

If any of these exist in both branches under different names or definitions, use the backend version and update any frontend references accordingly.

### 2.3 Verify frontend model types exist
Confirm these types are defined somewhere in the merged project (they come from the frontend):
- `KPIMetric` — in `Models/KPIMetric.swift`
- `QueryRecord` — in `Models/QueryRecord.swift`
- `HeatmapCell` — in `Models/HeatmapData.swift`
- `SentimentDataPoint` — in `Models/SentimentData.swift`
- `ModelEfficiency` — in `Models/ModelEfficiency.swift`
- `ModelTier`, `QueryCategory`, `QueryStatus`, `SentimentScore` — in `Models/QueryRecord.swift`
- `DashboardServiceProtocol` — in `Services/DashboardService.swift`

---

## Step 3 — Add LiveDashboardService

**3.1** Add `LiveDashboardService.swift` to the `Services/` folder in the project navigator.

The file is provided as part of this integration package. Its full path in this package is `CSCIntegration/LiveDashboardService.swift`.

**3.2** Verify `ModelEfficiency` field names match what `LiveDashboardService` expects.

Open `Models/ModelEfficiency.swift` from the frontend. Confirm it has these fields (names must match exactly):
```swift
struct ModelEfficiency: Identifiable {
    let id: UUID
    let tier: ModelTier
    let queryCount: Int
    let averageResponseSeconds: Double
    let resolutionRate: Double       // 0.0 – 1.0
    let shareOfTotal: Double         // 0.0 – 1.0
}
```

If field names differ, update the `fetchModelEfficiency()` method in `LiveDashboardService.swift` to use the correct field names. Do not modify `ModelEfficiency.swift`.

**3.3** Verify `SentimentDataPoint` field names match what `LiveDashboardService` expects.

Open `Models/SentimentData.swift` from the frontend. Confirm it has these fields:
```swift
struct SentimentDataPoint: Identifiable {
    let id: UUID
    let date: Date
    let sentiment: SentimentScore
    let count: Int
}
```

If field names differ, update `fetchSentimentTrend()` in `LiveDashboardService.swift`. Do not modify `SentimentData.swift`.

---

## Step 4 — Update NexusHRApp.swift

Open `NexusHRApp.swift` and apply these changes. Do not modify any other file in `App/`.

**4.1** Add import at the top:
```swift
import SwiftData
```

**4.2** Add the `ModelContainer` property to the `App` struct (before `body`):
```swift
let container: ModelContainer = {
    let schema = Schema([
        DocumentChunk.self,
        ConversacionLog.self,
        Colaborador.self,
        Ticket.self
    ])
    let config = ModelConfiguration("csc-nexushr", schema: schema)
    return try! ModelContainer(for: schema, configurations: config)
}()
```

**4.3** Find the line that instantiates `DashboardViewModel` with `MockDashboardService`. It will look like:
```swift
@StateObject private var dashboardVM = DashboardViewModel(service: MockDashboardService())
```

Replace it with:
```swift
@StateObject private var dashboardVM = DashboardViewModel(service: LiveDashboardService(container: container))
```

**4.4** Find the `body` property. Add `.modelContainer(container)` and `.task` modifiers to `WindowGroup`:
```swift
var body: some Scene {
    WindowGroup {
        MainWindowView()
            .task { await arrancarApp() }
    }
    .modelContainer(container)
    .defaultSize(width: 1200, height: 750)
}
```

**4.5** Add the `arrancarApp()` method to the `App` struct:
```swift
@MainActor
private func arrancarApp() async {
    // Seed test collaborators on first launch
    let context = container.mainContext
    try? ColaboradorSeeder.sembrarSiNecesario(context: context)

    // Index PDFs in background — only runs once per document
    Task.detached(priority: .background) {
        do {
            let service = DocumentoIndexerService(modelContainer: container)
            let resultados = try await service.indexarTodosLosDocumentos()
            let total = resultados.values.reduce(0) { $0 + $1.chunksIndexados }
            print("[NexusHR] Indexación completa — \(total) chunks")
        } catch {
            print("[NexusHR] Error indexación: \(error)")
        }
    }
}
```

---

## Step 5 — Build and Verify

**5.1** Build the project (`Cmd+B`). Fix any compile errors before proceeding. Common errors and fixes:

| Error | Fix |
|---|---|
| `Cannot find type 'ConversacionLog'` | File not added to target — check membership in File Inspector |
| `'@main' attribute cannot be applied to a type in a module with top-level code` | Two `@main` structs exist — delete `CSCTestApp.swift` |
| `No such module 'FoundationModels'` | Deployment target must be macOS 15.1+ for FoundationModels, or 14.0+ with availability checks. Add `@available(macOS 15.1, *)` guards if needed |
| `Type 'LiveDashboardService' does not conform to 'DashboardServiceProtocol'` | A method signature in the protocol doesn't match — compare method names and parameter labels exactly |
| `Cannot find 'ColaboradorSeeder' in scope` | `ColaboradorSeeder.swift` not added to target |

**5.2** Run the app. On first launch:
- The console should print `[Seeder] Colaboradores insertados correctamente.`
- After ~30 seconds: `[NexusHR] Indexación completa — N chunks`
- The dashboard should display KPI cards. If SwiftData has no conversation logs yet, the dashboard falls back to mock data automatically — this is expected.

**5.3** Verify the fallback works: with no real data, each `fetch*` method in `LiveDashboardService` returns mock data. The dashboard must render without empty states.

---

## Step 6 — Wire the Simulator to Generate Real Data

To populate the dashboard with real SwiftData records:

**6.1** The `SimuladorView` from the backend must be accessible from the unified app. Add it to `MainWindowView.swift` or `SidebarView.swift` as a navigation destination. The sidebar item label is "Simulador".

**6.2** In `SimuladorView.swift`, verify the `init(container:)` receives the same `ModelContainer` instance used in `NexusHRApp.swift`. Pass it via `@Environment(\.modelContainer)` or inject it explicitly.

**6.3** Send several test messages in the simulator using different keywords:
- Simple route: `"¿Cuántos días de vacaciones da la ley?"`
- Sensitive route: `"¿Cuánto fue mi nómina esta quincena?"` (set colaboradorID to `EMP-001423`)
- Escalation route: `"Quiero denunciar acoso laboral"`

After each message, pull to refresh or wait 30 seconds for the dashboard auto-refresh timer to fire. KPI values should update with real data.

---

## Step 7 — Seed Historical Data (Optional but Recommended for Demo)

If the dashboard needs to look populated from the first second of the demo without running through the simulator manually, add this call inside `arrancarApp()` after the seeder:

```swift
// Seed historical conversation logs for dashboard demo
// Remove this block before production deployment
try? HistoricalDataSeeder.sembrarSiNecesario(context: context)
```

`HistoricalDataSeeder` is a separate file that generates ~200 synthetic `ConversacionLog` records and ~25 `Ticket` records distributed over the past 30 days. Request this file separately if needed.

---

## What NOT to Change

To preserve frontend integrity, do not modify any of these files:

- Anything in `Views/` 
- Anything in `ViewModels/`
- `Models/KPIMetric.swift`
- `Models/QueryRecord.swift`
- `Models/HeatmapData.swift`
- `Models/SentimentData.swift`
- `Models/ModelEfficiency.swift`
- `Services/MockDashboardService` (keep it — needed for SwiftUI previews)
- `Services/MLOrchestrator.swift` (leave stubs as-is for now)
- `Services/DataAnonymizer.swift`
- `Core/Theme/`
- `Core/Extensions/`

---

## File Manifest — What This Integration Adds to the Project

| File | Destination | Action |
|---|---|---|
| `LiveDashboardService.swift` | `Services/` | Add new |
| `DocumentChunk.swift` | `Models/` | Add new (backend) |
| `ConversacionLog.swift` | `Models/` | Add new (backend) |
| `Colaborador.swift` | `Models/` | Add new (backend) |
| `Ticket.swift` | `Models/` | Add new (backend) |
| `RouterMockup.swift` | `Services/` | Add new (backend) |
| `ClusterMockup.swift` | `Services/` | Add new (backend) |
| `KeychainManager.swift` | `Services/` | Add new (backend) |
| `CryptoKit` (system) | — | No action needed, system framework |
| `PDFExtractor.swift` | `Services/` | Add new (backend) |
| `TextChunker.swift` | `Services/` | Add new (backend) |
| `DocumentIndexer.swift` | `Services/` | Add new (backend) |
| `DocumentoIndexerService.swift` | `Services/` | Add new (backend) |
| `DocumentoRegistry.swift` | `Services/` | Add new (backend) |
| `RAGRetriever.swift` | `Services/` | Add new (backend) |
| `ColaboradorSeeder.swift` | `Services/` | Add new (backend) |
| `MessageSenderMock.swift` | `Services/` | Add new (backend) |
| `PipelineOrchestrator.swift` | `Services/` | Add new (backend) |
| `IngestError.swift` | `Models/` | Add new (backend) |
| `SimuladorView.swift` | `Views/` | Add new (backend) |
| `IndexacionView.swift` | `Views/` | Add new (backend) |
| `BusquedaView.swift` | `Views/` | Add new (backend) |
| `EMP001423_*.pdf` (5 files) | Bundle Resources | Add to target |
| `EMP003812_*.pdf` (5 files) | Bundle Resources | Add to target |
| `NexusHRApp.swift` | `App/` | **Modify** (Step 4 only) |
| `CSCTestApp.swift` | — | **Delete** |

---

## Mapping Reference

Quick reference for how backend types map to frontend types:

| Backend | Frontend |
|---|---|
| `RutaAgente.simple` | `ModelTier.basic` |
| `RutaAgente.sensible` | `ModelTier.intermediate` |
| `RutaAgente.escalar` | `ModelTier.hrAgent` |
| `ConversacionLog.resuelta == true` | `QueryStatus.resolved` |
| `ConversacionLog.modo == "escalado"` | `QueryStatus.escalated` |
| `ConversacionLog.resuelta == false && modo != "escalado"` | `QueryStatus.inProgress` |
| `clusterID == 0` | `QueryCategory.nomina` |
| `clusterID == 1` | `QueryCategory.beneficios` |
| `clusterID == 2` | `QueryCategory.vacaciones` |
| `clusterID == 3` | `QueryCategory.legal` |
| `scoreConfianza >= 0.75 && resuelta` | `SentimentScore.positive` |
| `scoreConfianza < 0.50` | `SentimentScore.negative` |
| `cluster.tono == "ansioso"` | `SentimentScore.neutral` |
| `cluster.tono == "frustrado"` | `SentimentScore.negative` |
