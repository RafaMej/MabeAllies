internal import SwiftData
internal import Foundation

@Model
final class ConversacionLog {
    var id: UUID
    var colaboradorID: String
    var mensajeEntrada: String
    var respuestaAgente: String
    var modo: String
    var resuelta: Bool
    var duracionSegundos: Double
    var timestamp: Date
    var scoreConfianza: Double
    var clusterID: Int
    var colaborador: Colaborador?

    init(colaboradorID: String, mensajeEntrada: String, respuestaAgente: String,
         modo: String, resuelta: Bool, duracionSegundos: Double,
         scoreConfianza: Double) {
        self.id = UUID()
        self.colaboradorID = colaboradorID
        self.mensajeEntrada = mensajeEntrada
        self.respuestaAgente = respuestaAgente
        self.modo = modo
        self.resuelta = resuelta
        self.duracionSegundos = duracionSegundos
        self.timestamp = Date()
        self.scoreConfianza = scoreConfianza
        self.clusterID = -1
    }
}
