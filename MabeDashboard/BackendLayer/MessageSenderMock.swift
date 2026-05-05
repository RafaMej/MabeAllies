/*import Foundation

actor MessageSenderMock {
    private(set) var historialEnviados: [(fecha: Date, destinatario: String, texto: String)] = []

    func enviar(respuesta: String, a destinatario: String) async {
        try? await Task.sleep(nanoseconds: 100_000_000)
        historialEnviados.append((Date(), destinatario, respuesta))
        print("[MessageSender] → \(destinatario): \(respuesta.prefix(80))…")
    }
}
*/
