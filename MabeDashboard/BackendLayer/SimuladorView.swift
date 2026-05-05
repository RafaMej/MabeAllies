// SimuladorView.swift — iPadOS
// Adaptaciones vs macOS:
//   • Color(nsColor: .windowBackgroundColor) → Color(uiColor: .systemGroupedBackground)
//   • Color(nsColor: .textBackgroundColor)   → Color(uiColor: .systemBackground)
//   • Color(nsColor: .controlBackgroundColor)→ Color(uiColor: .secondarySystemBackground)
//   • .frame(minWidth: 600, minHeight: 500) removido — NavigationSplitView gestiona el tamaño
//   • FirestoreMessageSender y FirestoreConversationListener viven en Services/;
//     este archivo solo tiene SimuladorView y sus subvistas

internal import SwiftUI
internal import SwiftData
internal import FirebaseAuth

struct SimuladorView: View {
    @Environment(\.modelContext) private var modelContext

    @StateObject private var orquestador: PipelineOrchestrator
    @State private var firestoreListener = FirestoreConversationListener()

    @State private var mensajeActual  = ""
    @State private var colaboradorID  = "aRpkP7AwTlg7Y8JkrDTwHbdfp043"
    @State private var historial: [TurnoConversacion] = []
    @State private var error: String?
    @State private var modoEscucha    = false
    @State private var agenteUID: String = Auth.auth().currentUser?.uid ?? "sin-autenticar"

    init(container: ModelContainer) {
        let uid = Auth.auth().currentUser?.uid ?? "sin-autenticar"
        _orquestador = StateObject(wrappedValue: PipelineOrchestrator(container: container, agenteUID: uid))
    }

    var body: some View {
        VStack(spacing: 0) {

            // MARK: Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Simulador de conversación").font(.headline)
                    Text("ID: \(colaboradorID)").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()

                if modoEscucha {
                    HStack(spacing: 4) {
                        Circle().fill(.green).frame(width: 7, height: 7)
                        Text("iMessage activo").font(.caption2).foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(.green.opacity(0.1), in: Capsule())
                }

                if let ruta = orquestador.ultimaRuta { RutaBadge(ruta: ruta) }

                Button(modoEscucha ? "Detener iMessage" : "Escuchar iMessage") {
                    modoEscucha ? detenerEscucha() : iniciarEscucha()
                }
                .buttonStyle(.borderless)
                .foregroundStyle(modoEscucha ? .red : .accentColor)

                Button("Nueva conv.") { historial = []; orquestador.ultimaRuta = nil; error = nil }
                    .buttonStyle(.borderless).foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color(uiColor: .systemGroupedBackground)) // ← nsColor reemplazado

            Divider()

            // MARK: Chat area
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        if historial.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 40)).foregroundStyle(.tertiary)
                                Text("Escribe un mensaje para empezar").foregroundStyle(.secondary)
                                Text("O activa \"Escuchar iMessage\" para recibir mensajes reales")
                                    .font(.caption).foregroundStyle(.tertiary).multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity).padding(.top, 60)
                        } else {
                            ForEach(historial) { turno in
                                BurbujaMensaje(turno: turno).id(turno.id)
                            }
                        }

                        if orquestador.procesando {
                            HStack(spacing: 8) {
                                ProgressView().scaleEffect(0.7)
                                Text("Procesando…").font(.caption).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading).id("procesando")
                        }
                    }
                    .padding(20)
                }
                .background(Color(uiColor: .systemBackground)) // ← nsColor reemplazado
                .onChange(of: historial.count) { old, new in
                    guard new > old else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation { proxy.scrollTo(historial.last?.id, anchor: .bottom) }
                    }
                }
                .onChange(of: orquestador.procesando) { _, procesando in
                    if procesando {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation { proxy.scrollTo("procesando", anchor: .bottom) }
                        }
                    }
                }
            }

            // MARK: Error banner
            if let err = error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    Text(err).font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button("OK") { error = nil }.buttonStyle(.borderless)
                }
                .padding(10).background(.orange.opacity(0.1))
                Divider()
            }

            // MARK: Input area
            HStack(spacing: 12) {
                TextField("Escribe tu mensaje…", text: $mensajeActual, axis: .vertical)
                    .textFieldStyle(.roundedBorder).lineLimit(1...4)
                    .onSubmit { enviar() }

                Button(action: enviar) {
                    Image(systemName: "arrow.up.circle.fill").font(.system(size: 32))
                        .foregroundStyle(mensajeActual.isEmpty || orquestador.procesando ? .secondary : Color.accentColor)
                }
                .buttonStyle(.plain)
                .disabled(mensajeActual.isEmpty || orquestador.procesando)
            }
            .padding(16)
            .background(Color(uiColor: .systemGroupedBackground)) // ← nsColor reemplazado
        }
        // .frame(minWidth: 600, minHeight: 500) ← REMOVIDO — iPadOS usa NavigationSplitView
        .navigationTitle("Simulador")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            agenteUID = Auth.auth().currentUser?.uid ?? "sin-autenticar"
            print("[SimuladorView] Agente UID: \(agenteUID)")
        }
        .onDisappear { detenerEscucha() }
    }

    // MARK: — Firestore listener

    private func iniciarEscucha() {
        modoEscucha = true
        firestoreListener.iniciar(colaboradorUID: colaboradorID, agenteUID: agenteUID) { textoRecibido in
            historial.append(TurnoConversacion(contenido: textoRecibido, esUsuario: true, timestamp: Date()))
            do {
                let respuesta = try await orquestador.procesar(
                    mensaje: textoRecibido, colaboradorID: colaboradorID, historial: historial)
                historial.append(TurnoConversacion(contenido: respuesta.texto, esUsuario: false, timestamp: Date()))
            } catch { self.error = error.localizedDescription }
        }
    }

    private func detenerEscucha() { modoEscucha = false; firestoreListener.detener() }

    private func enviar() {
        let texto = mensajeActual.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !texto.isEmpty, !orquestador.procesando else { return }
        historial.append(TurnoConversacion(contenido: texto, esUsuario: true, timestamp: Date()))
        let snap = historial; mensajeActual = ""; error = nil
        Task {
            do {
                let r = try await orquestador.procesar(mensaje: texto, colaboradorID: colaboradorID, historial: snap)
                await MainActor.run { historial.append(TurnoConversacion(contenido: r.texto, esUsuario: false, timestamp: Date())) }
            } catch { await MainActor.run { self.error = error.localizedDescription } }
        }
    }
}

// MARK: — BurbujaMensaje

struct BurbujaMensaje: View {
    let turno: TurnoConversacion
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if turno.esUsuario { Spacer(minLength: 80) }
            VStack(alignment: turno.esUsuario ? .trailing : .leading, spacing: 4) {
                Text(turno.contenido)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 16).fill(
                        turno.esUsuario ? Color.accentColor : Color(uiColor: .secondarySystemBackground) // ← nsColor reemplazado
                    ))
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(
                        turno.esUsuario ? Color.clear : Color.primary.opacity(0.1), lineWidth: 1))
                    .foregroundStyle(turno.esUsuario ? Color.white : Color.primary)
                    .textSelection(.enabled)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                Text(turno.timestamp, style: .time).font(.caption2).foregroundStyle(.tertiary)
            }
            if !turno.esUsuario { Spacer(minLength: 80) }
        }
        .frame(maxWidth: .infinity, alignment: turno.esUsuario ? .trailing : .leading)
    }
}

// MARK: — RutaBadge

struct RutaBadge: View {
    let ruta: RutaAgente
    var color: Color {
        switch ruta { case .simple: return .green; case .sensible: return .orange; case .escalar: return .red }
    }
    var body: some View {
        Text(ruta.rawValue.uppercased()).font(.caption.bold())
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}
