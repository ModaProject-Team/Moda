//
//  FriendAddView.swift
//  Moda
//
//  Created by hyunMac on 11/16/25.
//

import SwiftUI
import Observation

// MARK: - State
private struct FriendAddState {
    var query: String = ""
    let maxLength: Int = 20

    // 검색 관련 상태
    var results: [FriendSearchItem] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var hasSearched: Bool = false // 첫 검색 여부
}

//MARK: 검색 결과 모델(목 데이터용 간단 모델 추후 수정필요)
private struct FriendSearchItem: Identifiable, Hashable {
    let id: String      // 사용자 ID(고유)
    let nickname: String
}

// MARK: - Intent
private enum FriendAddIntent {
    case queryChanged(String)
    case clearTapped
    case searchSubmitted
}

// MARK: - Store (@Observable)
@MainActor
@Observable
private final class FriendAddStore {
    var state = FriendAddState()
    private var searchTask: Task<Void, Never>?

    func send(_ intent: FriendAddIntent) {
        switch intent {
        case .queryChanged(let text):
            handleQueryChanged(text)
        case .clearTapped:
            state.query = ""
        case .searchSubmitted:
            handleSearchSubmitted()
        }
    }

    // MARK: - Handlers
    private func handleQueryChanged(_ text: String) {
        // 입력 중 최대길이 도달시 입력 방지
        state.query = clampToMaxLength(text)
    }

    private func handleSearchSubmitted() {
        // 필요 시 공백 제거 + 길이 보정
        let trimmed = state.query.trimmingCharacters(in: .whitespacesAndNewlines)
        state.query = clampToMaxLength(trimmed)

        // 빈 입력은 무시
        guard !state.query.isEmpty else { return }

        // 첫 검색 실행 표시
        state.hasSearched = true

        // 이전 검색 취소
        searchTask?.cancel()

        // 로딩 시작
        state.isLoading = true
        state.errorMessage = nil
        state.results = []

        let query = state.query

        //TODO: 목 네트워크 호출,네트워크로 추후 대체
        searchTask = Task {
            do {
                let items = try await fetchMockResults(for: query)
                state.results = items
            } catch {
                state.errorMessage = error.localizedDescription
            }
            state.isLoading = false
        }
    }

    // MARK: - Helpers
    private func clampToMaxLength(_ text: String) -> String {
        if text.count > state.maxLength {
            return String(text.prefix(state.maxLength))
        } else {
            return text
        }
    }

    // TODO: 목 데이터 로더, 네트워크로 추후 대체
    private func fetchMockResults(for query: String) async throws -> [FriendSearchItem] {
        // 네트워크 지연 흉내
        try await Task.sleep(for: .milliseconds(700))

        let lower = query.lowercased()
        // 특정 키워드로 빈/에러 케이스 테스트 가능
        if lower == "empty" { return [] }
        if lower == "error" { throw URLError(.badServerResponse) }

        // 간단한 목 결과
        return (1...8).map { i in
            FriendSearchItem(
                id: "\(lower)_\(i)",
                nickname: "\(query.capitalized) \(i)"
            )
        }
    }
}

// MARK: - View
struct FriendAddView: View {
    @State private var store = FriendAddStore()
    @FocusState private var isSearching: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            FriendIDSearchBar(
                text: Binding(
                    get: { store.state.query },
                    set: { store.send(.queryChanged($0)) }
                ),
                isFocused: _isSearching,
                maxLength: store.state.maxLength,
                onSubmit: {
                    // 키보드의 Search 버튼을 눌렀을 때만 검색
                    store.send(.searchSubmitted)
                    isSearching = false
                }, onClear: {
                    store.send(.clearTapped)
                }
            )

            // 결과 영역
            Group {
                if store.state.isLoading {
                    ProgressView("검색 중…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else if let message = store.state.errorMessage {
                    ContentUnavailableView(
                        "오류가 발생했어요",
                        systemImage: "exclamationmark.triangle",
                        description: Text(message)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !store.state.hasSearched {
                    // 초기 상태(중립 안내): 아직 검색하지 않았을 때
                    ContentUnavailableView(
                        "친구를 검색해 보세요",
                        systemImage: "person.crop.circle.badge.magnifyingglass",
                        description: Text("ID를 입력하고 검색을 눌러보세요.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if store.state.results.isEmpty {
                    // 검색은 했지만 결과가 없을 때
                    ContentUnavailableView(
                        "검색 결과가 없어요",
                        systemImage: "person.fill.questionmark",
                        description: Text("다른 ID로 다시 시도해 보세요.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(store.state.results) { item in
                        FriendRow(item: item)
                    }
                    .listStyle(.plain)
                }
            }
        }
        .navigationTitle("ID로 추가")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                }
            }
            //TODO: 지금 검색버튼은 프리뷰 시연용, 나중에 어차피 키보드 올라왔을때 submit 버튼 눌렀을때 동작
            ToolbarItem(placement: .topBarTrailing) {
                Button("검색") {
                    store.send(.searchSubmitted)
                    isSearching = false
                }
                .disabled(store.state.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.state.isLoading)
            }
        }
        .task {
            // 진입 시 키보드 살짝 지연 후 포커스
            try? await Task.sleep(for: .milliseconds(250))
            await MainActor.run {
                isSearching = true
            }
        }
    }
}

// MARK: - Search Bar
private struct FriendIDSearchBar: View {
    @Binding var text: String
    @FocusState var isFocused: Bool
    let maxLength: Int
    let onSubmit: () -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                TextField("친구 ID", text: $text)
                    .textInputAutocapitalization(.none)
                    .keyboardType(.asciiCapable) // 영문/숫자 ID라면 권장
                    .disableAutocorrection(true)
                    .focused($isFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        onSubmit()
                    }

                Text("\(text.count)/\(maxLength)")
                    .monospacedDigit()
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            // 언더라인
            Rectangle()
                .fill(Color.primary.opacity(0.2))
                .frame(height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
}

// MARK: - Result Row, 나중에 분리, 재활용 고려하기
private struct FriendRow: View {
    let item: FriendSearchItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.nickname)
                    .font(.body.weight(.semibold))
                Text(item.id)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    NavigationStack {
        FriendAddView()
    }
}
