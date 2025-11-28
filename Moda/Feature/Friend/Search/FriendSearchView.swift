//
//  FriendSearchView.swift
//  Moda
//
//  Created by hyunMac on 11/12/25.
//

import SwiftUI
import Observation
import Kingfisher

private struct FriendSearchState {
    var query: String = ""
    var results: [People] = []
}

private enum FriendSearchAction {
    case queryChanged(String)
    case clearTapped
}

@MainActor
@Observable
private final class FriendSearchStore {
    private(set) var state = FriendSearchState()
    // 상위에서 주입된 원본 목록
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

struct FriendSearchView: View {
    @State private var store: FriendSearchStore
    @FocusState private var isSearching: Bool
    @Environment(\.dismiss) private var dismiss

    init(friends: [People]) {
        _store = State(initialValue: FriendSearchStore(sourceFriends: friends))
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                searchBarSection

                if store.state.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Spacer()
                } else {
                    searchResultsSection
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.gray1)
                }
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(250))
            await MainActor.run {
                isSearching = true
            }
        }
    }

    private var searchBarSection: some View {
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
            .font(.custom("SUIT-Medium", size: 14))
            .foregroundColor(.gray1)
        }
        .padding(.horizontal, 16)
        .background(Color.white)
    }

    private var searchResultsSection: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                HStack {
                    Text("검색 결과 \(store.state.results.count)")
                        .Body2()
                        .foregroundColor(.gray2)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                if store.state.results.isEmpty {
                    EmptyStateView(keyword: store.state.query)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(store.state.results) { person in
                            FriendRowView(people: person)
                        }
                    }
                }
            }
            .padding(.bottom, 100)
        }
    }
}

private struct FriendSearchBar: View {
    @Binding var text: String
    @FocusState var isFocused: Bool
    var onClear: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)

            TextField("검색", text: $text)
                .font(.system(size: 16))
                .textInputAutocapitalization(.none)
                .disableAutocorrection(true)
                .focused($isFocused)
                .submitLabel(.search)

            if !text.isEmpty {
                Button {
                    onClear()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.gray.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray5)
        )
    }
}

private struct FriendRowView: View {
    let people: People

    var body: some View {
        HStack(spacing: 12) {
            ProfileImageView(people: people)
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text(people.name)
                    .H2()
                    .foregroundColor(.gray1)

                if let msg = people.statusMessage, !msg.isEmpty {
                    Text(msg)
                        .Body2()
                        .foregroundColor(.gray2)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

private struct ProfileImageView: View {
    let people: People

    var body: some View {
        if let url = people.profileImageURL {
            KFImage(url)
                .requestModifier(KFHeaders.modifier)
                .placeholder { placeholder }
                .cacheOriginalImage()
                .fade(duration: 0.2)
                .cancelOnDisappear(true)
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
        } else {
            ZStack {
                Circle().fill(Color.gray3)
                Image(systemName: "person.fill")
                    .foregroundColor(.white)
            }
            .clipShape(Circle())
        }
    }

    private var placeholder: some View {
        Circle().fill(Color.gray3)
    }
}

private struct EmptyStateView: View {
    let keyword: String

    var body: some View {
        VStack(spacing: 12) {
            Spacer()

            Text("검색 결과가 없어요")
                .Body1()
                .foregroundColor(.gray2)

            if !keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("\"\(keyword)\"에 대한 친구를 찾지 못했어요")
                    .Body2()
                    .foregroundColor(.gray3)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: UIScreen.main.bounds.height - 300)
    }
}

#Preview {
    let sample: [People] = [
        People(id: "1", name: "영훈", statusMessage: "주말엔 등산!", profileImageURL: nil),
        People(id: "2", name: "지민", statusMessage: "Swift 즐겨요", profileImageURL: nil),
        People(id: "3", name: "수빈", statusMessage: "오늘도 화이팅", profileImageURL: nil),
        People(id: "4", name: "장수지", statusMessage: nil, profileImageURL: nil),
        People(id: "5", name: "금가경", statusMessage: "과제 중", profileImageURL: nil),
    ]

    NavigationStack {
        FriendSearchView(friends: sample)
    }
}
