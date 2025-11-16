//
//  FriendSearchView.swift
//  Moda
//
//  Created by hyunMac on 11/12/25.
//

import SwiftUI
import Observation

// MARK: - Model
private struct Friend: Identifiable, Hashable {
    let id: UUID
    var name: String
    var statusMessage: String?
}

// MARK: - State
private struct FriendSearchState {
    var query: String = ""
    var results: [Friend] = []
}

// MARK: - Intent
private enum FriendSearchIntent {
    case queryChanged(String)
    case clearTapped
}

// MARK: - Store (@Observable)
@Observable
private final class FriendSearchStore {

    // 관찰 대상 상태
    var state = FriendSearchState()

    // 간단한 더미 데이터
    private let allFriends: [Friend] = [
        Friend(id: UUID(), name: "영훈", statusMessage: "주말엔 등산!"),
        Friend(id: UUID(), name: "지민", statusMessage: "Swift 즐겨요"),
        Friend(id: UUID(), name: "수빈", statusMessage: "오늘도 화이팅"),
        Friend(id: UUID(), name: "장수지", statusMessage: nil),
        Friend(id: UUID(), name: "금가경", statusMessage: "과제 중")
    ]

    func send(_ intent: FriendSearchIntent) {
        switch intent {
        case .clearTapped:
            handleClearTapped()
        case .queryChanged(let text):
            handleQueryChanged(text)
        }
    }

    // MARK: - Handlers
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
            state.results = allFriends.filter {
                $0.name.localizedCaseInsensitiveContains(trimmed)
            }
        }
    }
}

// MARK: - View
struct FriendSearchView: View {
    // @Observable Store는 @State로 보유
    @State private var store = FriendSearchStore()
    @FocusState private var isSearching: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // 상단 검색 영역 (서치바)
            HStack(spacing: 8) {
                FriendSearchBar(
                    text: Binding(
                        get: { store.state.query },
                        set: { store.send(.queryChanged($0)) }
                    ),
                    isFocused: _isSearching,
                    onClear: { store.send(.clearTapped) }
                )
                .padding(.vertical, 8)

                Button("취소") {
                    store.send(.clearTapped)
                    isSearching = false
                    dismiss()
                }
                .foregroundStyle(.black)
            }
            .padding(.horizontal, 12)
            .background(.ultraThinMaterial)

            // 검색 결과 표시
            if store.state.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Spacer()
            } else {
                List {
                    Section {
                        if store.state.results.isEmpty {
                            EmptyStateView(keyword: store.state.query)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        } else {
                            ForEach(store.state.results) { friend in
                                FriendRowView(friend: friend)
                            }
                        }
                    } header: {
                        Text("검색 결과 \(store.state.results.count)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .listStyle(.plain)
            }
        }
        .task {
            // 진입 시 키보드 바로 올리기 (살짝 지연)
            try? await Task.sleep(for: .milliseconds(250))
            await MainActor.run {
                isSearching = true
            }
        }
    }
}

// MARK: - Search Field
private struct FriendSearchBar: View {
    @Binding var text: String
    @FocusState var isFocused: Bool
    var onClear: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("검색", text: $text)
                .textInputAutocapitalization(.none)
                .disableAutocorrection(true)
                .focused($isFocused)
                .submitLabel(.search)

            if !text.isEmpty {
                Button {
                    onClear()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
        )
    }
}

// MARK: - Row & Subviews
private struct FriendRowView: View {
    let friend: Friend

    var body: some View {
        HStack(spacing: 12) {
            // 간단한 기본 아바타
            ZStack {
                Circle().fill(Color.gray.opacity(0.2))
                Image(systemName: "person.fill")
                    .foregroundStyle(.secondary)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(friend.name)
                    .font(.body.weight(.semibold))

                if let msg = friend.statusMessage, !msg.isEmpty {
                    Text(msg)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

private struct EmptyStateView: View {
    let keyword: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 36, weight: .regular))
                .foregroundStyle(.secondary)
            Text("검색 결과가 없어요")
                .font(.headline)
            if !keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("“\(keyword)”에 대한 친구를 찾지 못했어요.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

#Preview {
    NavigationStack {
        FriendSearchView()
    }
}
