// FirestoreConversationListener.swift
internal import Foundation
internal import FirebaseFirestore
internal import Combine

/// Escucha mensajes nuevos del colaborador en Firestore
/// y los pasa al PipelineOrchestrator para procesarlos.
@MainActor
class FirestoreConversationListener: ObservableObject {
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var ultimoTimestampVisto: Date = Date() // ignora mensajes históricos

    /// Inicia la escucha de una conversación específica
    func iniciar(
        colaboradorUID: String,
        agenteUID: String,
        onMensajeRecibido: @escaping (String) async -> Void
    ) {
        let convID = ([colaboradorUID, agenteUID].sorted().joined(separator: "_"))
        let inicio = Timestamp(date: ultimoTimestampVisto)

        listener = db
            .collection("conversations")
            .document(convID)
            .collection("messages")
            .whereField("senderId", isEqualTo: colaboradorUID)   // solo mensajes del colaborador
            .whereField("timestamp", isGreaterThan: inicio)       // solo nuevos
            .order(by: "timestamp")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self, let snapshot else { return }

                for change in snapshot.documentChanges where change.type == .added {
                    let data = change.document.data()
                    guard let texto = data["text"] as? String, !texto.isEmpty else { continue }

                    // Actualiza el cursor para no reprocesar
                    if let ts = data["timestamp"] as? Timestamp {
                        self.ultimoTimestampVisto = ts.dateValue()
                    }

                    Task {
                        await onMensajeRecibido(texto)
                    }
                }
            }
    }

    func detener() {
        listener?.remove()
        listener = nil
    }
}
