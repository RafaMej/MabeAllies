// MabeDashboardApp.swift
// Nexus HR — iPadOS 17+
// Wires: SwiftData container → Firebase → PDF indexing → LiveDashboardService → UI
// Replaces macOS: WindowGroup scene modifiers (.windowStyle, .windowResizability,
//   .defaultSize, .hiddenTitleBar), NSApplicationDelegateAdaptor → UIApplicationDelegateAdaptor

internal import SwiftUI
internal import SwiftData
internal import FirebaseCore
internal import FirebaseAuth
internal import FirebaseFirestore

@main
struct MabeDashboardApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // Shared SwiftData container — idéntico al original
    static let container: ModelContainer = {
        let schema = Schema([
            DocumentChunk.self,
            ConversacionLog.self,
            Colaborador.self,
            Ticket.self
        ])
        let config = ModelConfiguration("csc-nexushr", schema: schema)
        return try! ModelContainer(for: schema, configurations: config)
    }()

    @StateObject private var dashboardVM = DashboardViewModel(
        service: LiveDashboardService(container: MabeDashboardApp.container)
    )

    var body: some Scene {
        WindowGroup {
            RootNavigationView()
                .environmentObject(dashboardVM)
                .task { await arrancarApp() }
        }
        .modelContainer(Self.container)
        // iPadOS no tiene .windowStyle, .windowResizability ni .defaultSize
    }

    // MARK: — Startup (idéntico al original CSCTestApp.arrancarApp)

    @MainActor
    private func arrancarApp() async {
        // 1. Auth anónima del agente
        await autenticarAgente()

        // 2. Sembrar colaboradores de prueba
        let context = Self.container.mainContext
        try? ColaboradorSeeder.sembrarSiNecesario(context: context)

        // 3. Indexar PDFs del bundle en background (una sola vez por doc)
        Task.detached(priority: .background) {
            do {
                let service = DocumentoIndexerService(modelContainer: Self.container)
                let resultados = try await service.indexarTodosLosDocumentos()
                let total = resultados.values.reduce(0) { $0 + $1.chunksIndexados }
                print("[NexusHR] Indexación completa — \(total) chunks")
            } catch {
                print("[NexusHR] Error indexación: \(error)")
            }
        }
    }

    private func autenticarAgente() async {
        guard Auth.auth().currentUser == nil else {
            print("[NexusHR] Sesión existente — UID: \(Auth.auth().currentUser!.uid)")
            return
        }
        do {
            let result = try await Auth.auth().signInAnonymously()
            let uid = result.user.uid
            print("[NexusHR] Agente autenticado — UID: \(uid)")
            // Crear documento del agente en Firestore
            let db = Firestore.firestore()
            try await db.collection("users").document(uid).setData([
                "displayName": "Agente RRHH Mabe",
                "isTyping": false
            ])
        } catch {
            print("[NexusHR] Error auth: \(error)")
        }
    }
}

// MARK: — AppDelegate (configura Firebase antes de cualquier escena)

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
