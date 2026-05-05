// LiveDashboardService.swift
// Implements DashboardServiceProtocol pulling real data from SwiftData.
// Drop this file into the Services/ folder and replace MockDashboardService
// with LiveDashboardService in NexusHRApp.swift.

internal import Foundation
internal import SwiftData
internal import SwiftUI

final class LiveDashboardService: DashboardServiceProtocol {

    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    // MARK: - KPIs

    func fetchKPIs() async throws -> [KPIMetric] {
        let context = ModelContext(container)

        let logs  = try context.fetch(FetchDescriptor<ConversacionLog>())
        let tickets = try context.fetch(FetchDescriptor<Ticket>())

        // ── Consultas activas (últimas 2 horas) ─────────────────────────────
        let dosHoras = Date().addingTimeInterval(-7_200)
        let activas = logs.filter { $0.timestamp >= dosHoras }.count

        // ── Resolución automática ────────────────────────────────────────────
        let resueltas = logs.filter { $0.resuelta }.count
        let tasaResolucion = logs.isEmpty ? 0.0 : Double(resueltas) / Double(logs.count) * 100

        // ── Tickets evitados = conversaciones resueltas sin escalar ──────────
        let evitados = logs.filter { $0.resuelta && $0.modo != "escalado" }.count

        // ── Horas ahorradas (baseline: 15 min por interacción resuelta) ──────
        let minutosAhorrados = Double(evitados) * 15.0
        let horasAhorradas   = minutosAhorrados / 60.0

        // ── Tendencias vs semana anterior ────────────────────────────────────
        let unaSemana   = Date().addingTimeInterval(-604_800)
        let dosSemanas  = Date().addingTimeInterval(-1_209_600)

        let logsEstaSemana    = logs.filter { $0.timestamp >= unaSemana }
        let logsSemanaAnterior = logs.filter { $0.timestamp >= dosSemanas && $0.timestamp < unaSemana }

        let trendConsultas: Double = {
            guard !logsSemanaAnterior.isEmpty else { return 0 }
            return (Double(logsEstaSemana.count) - Double(logsSemanaAnterior.count))
                / Double(logsSemanaAnterior.count) * 100
        }()

        let resEstaSemana     = logsEstaSemana.filter(\.resuelta).count
        let resSemanaAnterior = logsSemanaAnterior.filter(\.resuelta).count
        let tasaEsta    = logsEstaSemana.isEmpty ? 0.0
                          : Double(resEstaSemana) / Double(logsEstaSemana.count) * 100
        let tasaAnterior = logsSemanaAnterior.isEmpty ? 0.0
                          : Double(resSemanaAnterior) / Double(logsSemanaAnterior.count) * 100
        let trendTasa   = tasaEsta - tasaAnterior

        return [
            KPIMetric(
                title: "Tickets Evitados",
                value: evitados.formatted(),
                trend: trendConsultas,
                icon: "ticket.fill"
            ),
            KPIMetric(
                title: "Horas Ahorradas",
                value: String(format: "%.0f hrs", horasAhorradas),
                trend: trendConsultas,
                icon: "clock.fill"
            ),
            KPIMetric(
                title: "Resolución Automática",
                value: String(format: "%.0f%%", tasaResolucion),
                trend: trendTasa,
                icon: "cpu.fill"
            ),
            KPIMetric(
                title: "Consultas Activas",
                value: activas.formatted(),
                trend: 0.0,
                isLive: true,
                icon: "message.fill"
            ),
        ]
    }

    // MARK: - Heatmap

    func fetchHeatmapData(range: DateInterval) async throws -> [HeatmapCell] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<ConversacionLog>(
            predicate: #Predicate {
                $0.timestamp >= range.start && $0.timestamp <= range.end
            }
        )
        let logs = try context.fetch(descriptor)

        // Si no hay datos reales todavía, caer en mock realista
        guard !logs.isEmpty else { return HeatmapCell.mockData() }

        // Agrupar por (diaDeSemana, hora) y contar
        var conteos: [String: Int] = [:]
        let calendar = Calendar.current

        for log in logs {
            let componentes = calendar.dateComponents([.weekday, .hour], from: log.timestamp)
            // weekday: 1=Dom ... 7=Sáb → convertir a 0=Lun ... 6=Dom
            let weekday = ((componentes.weekday ?? 1) + 5) % 7
            let hour    = componentes.hour ?? 9
            let key     = "\(weekday)-\(hour)"
            conteos[key, default: 0] += 1
        }

        var cells: [HeatmapCell] = []
        for day in 0...6 {
            for hour in 6...22 {
                let key = "\(day)-\(hour)"
                cells.append(HeatmapCell(
                    hour: hour,
                    dayOfWeek: day,
                    queryCount: conteos[key] ?? 0
                ))
            }
        }
        return cells
    }

    // MARK: - Sentiment Trend

    func fetchSentimentTrend(range: DateInterval) async throws -> [SentimentDataPoint] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<ConversacionLog>(
            predicate: #Predicate {
                $0.timestamp >= range.start && $0.timestamp <= range.end
            },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        let logs = try context.fetch(descriptor)

        guard !logs.isEmpty else { return SentimentDataPoint.mockData() }

        // Agrupar por día y calcular distribución de sentiment
        var porDia: [Date: (pos: Int, neu: Int, neg: Int)] = [:]
        let calendar = Calendar.current

        for log in logs {
            let dia = calendar.startOfDay(for: log.timestamp)
            var bucket = porDia[dia] ?? (0, 0, 0)
            switch sentimentDe(log: log) {
            case .positive: bucket.pos += 1
            case .neutral:  bucket.neu += 1
            case .negative: bucket.neg += 1
            }
            porDia[dia] = bucket
        }

        return porDia.keys.sorted().flatMap { dia -> [SentimentDataPoint] in
            let (pos, neu, neg) = porDia[dia]!
            let total = Double(pos + neu + neg)
            let pPos = total > 0 ? (Double(pos) / total) * 100.0 : 0.0
            let pNeu = total > 0 ? (Double(neu) / total) * 100.0 : 0.0
            let pNeg = total > 0 ? (Double(neg) / total) * 100.0 : 0.0
            return [
                SentimentDataPoint(date: dia, sentiment: .positive, percentage: pPos),
                SentimentDataPoint(date: dia, sentiment: .neutral,  percentage: pNeu),
                SentimentDataPoint(date: dia, sentiment: .negative, percentage: pNeg),
            ]
        }
    }

    // MARK: - Recent Queries

    func fetchRecentQueries(limit: Int) async throws -> [QueryRecord] {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<ConversacionLog>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        let logs = try context.fetch(descriptor)

        // Si no hay datos reales caer en mock
        guard !logs.isEmpty else { return Array(QueryRecord.mockData.prefix(limit)) }

        return logs.map { log in
            QueryRecord(
                id: log.id,
                timestamp: log.timestamp,
                category: categoriaDe(log: log),
                modelUsed: modelTierDe(ruta: log.modo),
                status: statusDe(log: log),
                sentiment: sentimentDe(log: log),
                isAnonymized: true
            )
        }
    }

    // MARK: - Model Efficiency

    func fetchModelEfficiency() async throws -> [ModelEfficiency] {
        let context = ModelContext(container)
        let logs = try context.fetch(FetchDescriptor<ConversacionLog>())

        guard !logs.isEmpty else { return ModelEfficiency.mockData }

        let simple   = logs.filter { $0.modo == RutaAgente.simple.rawValue }
        let sensible = logs.filter { $0.modo == RutaAgente.sensible.rawValue }
        let escalado = logs.filter { $0.modo == RutaAgente.escalar.rawValue }
        let total    = Double(logs.count)

        let tiempoSimple   = simple.isEmpty   ? 0.0 : simple.map(\.duracionSegundos).reduce(0,+)   / Double(simple.count)
        let tiempoSensible = sensible.isEmpty ? 0.0 : sensible.map(\.duracionSegundos).reduce(0,+) / Double(sensible.count)
        let tiempoEscalado = escalado.isEmpty ? 0.0 : escalado.map(\.duracionSegundos).reduce(0,+) / Double(escalado.count)

        return [
            ModelEfficiency(
                id: UUID(),
                modelName: "Basic",
                percentage: total > 0 ? (Double(simple.count) / total) * 100.0 : 0.0,
                color: .green,
                consultationCount: simple.count
            ),
            ModelEfficiency(
                id: UUID(),
                modelName: "Intermediate",
                percentage: total > 0 ? (Double(sensible.count) / total) * 100.0 : 0.0,
                color: .orange,
                consultationCount: sensible.count
            ),
            ModelEfficiency(
                id: UUID(),
                modelName: "HR Agent",
                percentage: total > 0 ? (Double(escalado.count) / total) * 100.0 : 0.0,
                color: .red,
                consultationCount: escalado.count
            ),
        ]
    }

    // MARK: - Mapping helpers

    /// Ruta → ModelTier
    private func modelTierDe(ruta: String) -> ModelTier {
        switch ruta {
        case RutaAgente.simple.rawValue:   return .basic
        case RutaAgente.sensible.rawValue: return .intermediate
        default:                           return .hrAgent
        }
    }

    /// ConversacionLog → QueryStatus
    private func statusDe(log: ConversacionLog) -> QueryStatus {
        if log.modo == RutaAgente.escalar.rawValue { return .escalated }
        return log.resuelta ? .resolved : .inProgress
    }

    /// ClusterID + tono + confianza → SentimentScore
    private func sentimentDe(log: ConversacionLog) -> SentimentScore {
        // Escalado o cluster frustrado → negativo
        if log.modo == RutaAgente.escalar.rawValue { return .negative }

        let cluster = ClusterMockup.clusters.first { $0.id == log.clusterID }
        if cluster?.tono == "frustrado" { return .negative }
        if cluster?.tono == "ansioso"   { return .neutral  }

        // Score de confianza como señal de sentiment
        if log.scoreConfianza >= 0.75 && log.resuelta { return .positive }
        if log.scoreConfianza < 0.50                  { return .negative }
        return .neutral
    }

    /// ClusterID → QueryCategory
    private func categoriaDe(log: ConversacionLog) -> QueryCategory {
        switch log.clusterID {
        case 0: return .nomina
        case 1: return .beneficios
        case 2: return .vacaciones
        case 3: return .legal
        default:
            // Fallback por palabras clave del mensaje
            let texto = log.mensajeEntrada.lowercased()
            if texto.contains("vacacion") || texto.contains("permiso") { return .vacaciones }
            if texto.contains("nómin") || texto.contains("sueldo")     { return .nomina     }
            if texto.contains("legal") || texto.contains("demanda")    { return .legal      }
            if texto.contains("clima") || texto.contains("ambiente")   { return .clima      }
            if texto.contains("capaci") || texto.contains("curso")     { return .capacitacion }
            return .beneficios
        }
    }
}

