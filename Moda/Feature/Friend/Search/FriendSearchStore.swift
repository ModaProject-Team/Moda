//
//  FriendSearchStore.swift
//  Moda
//
//  Created by 금가경 on 11/29/25.
//

import SwiftUI
import Observation

@MainActor
@Observable
final class FriendSearchStore {
    private(set) var state = FriendSearchState()
    private var sourceFriends: [People] = []

    init(sourceFriends: [People] = []) {
        self.sourceFriends = sourceFriends
    }

    func send(_ action: FriendSearchAction) {
        switch action {
        case .clearTapped:
            handleClearTapped()

        case .queryChanged(let text):
            handleQueryChanged(text)
        }
    }

    private func handleClearTapped() {
        state.query = ""
        state.results = []
    }

    private func handleQueryChanged(_ text: String) {
        state.query = text
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            state.results = []
        } else {
            applyFilter()
        }
    }

    private func applyFilter() {
        let trimmed = state.query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            state.results = []
        } else {
            state.results = sourceFriends.filter {
                $0.name.localizedCaseInsensitiveContains(trimmed)
            }
        }
    }
}
