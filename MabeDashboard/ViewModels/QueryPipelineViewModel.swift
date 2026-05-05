// QueryPipelineViewModel.swift
// ViewModel for the query pipeline table and live query tracking.

internal import Foundation
internal import Combine
internal import SwiftUI

@MainActor
final class QueryPipelineViewModel: ObservableObject {

    // MARK: — Published State

    @Published var queries: [QueryRecord] = []
    @Published var sortOrder: [KeyPathComparator<QueryRecord>] = [
        KeyPathComparator(\QueryRecord.timestamp, order: .reverse)
    ]
    @Published var filterCategory: QueryCategory? = nil
    @Published var filterStatus: QueryStatus? = nil
    @Published var searchText: String = ""

    // MARK: — Derived

    var filteredQueries: [QueryRecord] {
        queries.filter { record in
            let matchesCategory = filterCategory == nil || record.category == filterCategory
            let matchesStatus = filterStatus == nil || record.status == filterStatus
            let matchesSearch = searchText.isEmpty ||
                record.category.rawValue.localizedCaseInsensitiveContains(searchText) ||
                record.modelUsed.rawValue.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesStatus && matchesSearch
        }
    }

    var activeCount: Int {
        queries.filter { $0.status == .inProgress }.count
    }

    var escalatedCount: Int {
        queries.filter { $0.status == .escalated }.count
    }

    var resolvedTodayCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return queries.filter { $0.status == .resolved && $0.timestamp >= today }.count
    }

    // MARK: — Actions

    func loadQueries(from records: [QueryRecord]) {
        // INTEGRATION POINT: Apply DataAnonymizer before assigning
        self.queries = records.map { DataAnonymizer.anonymize($0) }
    }
}
