// FirestoreMessageSender.swift
internal import Foundation
internal import FirebaseFirestore
internal import FirebaseAuth

/// Reemplaza MessageSenderMock — envía respuestas del agente a Firestore
/// usando el mismo esquema de datos que el repo iMessage.
actor FirestoreMessageSender {
    private let db = Firestore.firestore()

    /// UID fijo del agente de RRHH en Firebase (créalo una vez en Firebase Console)
    let agenteUID: String

    init(agenteUID: String) {
        self.agenteUID = agenteUID
    }

    /// conversationId determinístico — igual que iMessage repo
    func conversationId(para colaboradorUID: String) -> String {
        [colaboradorUID, agenteUID].sorted().joined(separator: "_")
    }

    func enviar(respuesta: String, a colaboradorUID: String) async {
        let convID = conversationId(para: colaboradorUID)
        let messageID = UUID().uuidString
        let ahora = Date()

        let messageData: [String: Any] = [
            "id": messageID,
            "senderId": agenteUID,
            "text": respuesta,
            "timestamp": Timestamp(date: ahora),
            "status": "sent",
            "reactions": [:]
        ]

        do {
            // 1. Escribe el mensaje
            try await db
                .collection("conversations")
                .document(convID)
                .collection("messages")
                .document(messageID)
                .setData(messageData)

            // 2. Actualiza el último mensaje de la conversación
            try await db
                .collection("conversations")
                .document(convID)
                .setData([
                    "participants": [colaboradorUID, agenteUID].sorted(),
                    "lastMessage": respuesta,
                    "lastMessageTimestamp": Timestamp(date: ahora),
                    "lastMessageSenderId": agenteUID,
                    "unreadCount": FieldValue.increment(Int64(1))
                ], merge: true)

            print("[FirestoreMessageSender] ✅ → \(colaboradorUID): \(respuesta.prefix(60))…")
        } catch {
            print("[FirestoreMessageSender] ❌ Error: \(error)")
        }
    }
}

