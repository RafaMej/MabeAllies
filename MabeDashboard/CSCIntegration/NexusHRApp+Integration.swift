// NexusHRApp+Integration.swift
// Shows exactly what to change in NexusHRApp.swift to wire LiveDashboardService.
// This is NOT a separate file to add — it shows the diff you need to apply.

/*
 BEFORE (their current NexusHRApp.swift):
 ─────────────────────────────────────────
 @StateObject private var dashboardVM = DashboardViewModel(service: MockDashboardService())

 AFTER (replace with):
 ─────────────────────────────────────────
 // 1. Add import at top
 import SwiftData

 // 2. Add container property
 let container: ModelContainer = {
     let schema = Schema([
         DocumentChunk.self,
         ConversacionLog.self,
         Colaborador.self,
         Ticket.self
     ])
     let config = ModelConfiguration("csc-test", schema: schema)
     return try! ModelContainer(for: schema, configurations: config)
 }()

 // 3. Replace MockDashboardService with LiveDashboardService
 @StateObject private var dashboardVM = DashboardViewModel(
     service: LiveDashboardService(container: container)
 )

 // 4. Add .modelContainer modifier to WindowGroup
 var body: some Scene {
     WindowGroup {
         MainWindowView()
             .task { await arrancarApp() }   // seeds data on first launch
     }
     .modelContainer(container)
 }

 // 5. Add arrancarApp() — seeds colaboradores and indexes PDFs
 @MainActor
 private func arrancarApp() async {
     let context = container.mainContext
     try? ColaboradorSeeder.sembrarSiNecesario(context: context)
     Task.detached(priority: .background) {
         let service = DocumentoIndexerService(modelContainer: container)
         try? await service.indexarTodosLosDocumentos()
     }
 }
*/
