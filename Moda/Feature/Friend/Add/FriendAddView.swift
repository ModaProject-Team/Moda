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
        // 필요 시 공백 제거
        let trimmed = state.query.trimmingCharacters(in: .whitespacesAndNewlines)
        // 트리밍 후에도 길이 보정(붙여넣기/프로그램적 변경 대비)
        state.query = clampToMaxLength(trimmed)

        // 빈 입력은 무시
        guard !state.query.isEmpty else { return }

        // TODO: 여기서 실제 검색 로직을 호출하세요.
        // 예: await service.searchFriend(by: state.query)
        print("검색내용: \(state.query)")
    }

    // MARK: - Helpers
    private func clampToMaxLength(_ text: String) -> String {
        if text.count > state.maxLength {
            return String(text.prefix(state.maxLength))
        } else {
            return text
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

            Spacer()
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
                    .disableAutocorrection(true)
                    .focused($isFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        onSubmit()
                    }

                Text("\(text.count)/\(maxLength)")
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

#Preview {
    NavigationStack {
        FriendAddView()
    }
}
