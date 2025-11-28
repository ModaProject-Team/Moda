//
//  FriendSearchView.swift
//  Moda
//
//  Created by hyunMac on 11/12/25.
//

import SwiftUI
import Observation

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
        .enableSwipeBack()
        .task {
            try? await Task.sleep(for: .milliseconds(250))
            await MainActor.run {
                isSearching = true
            }
        }
    }

    private var searchBarSection: some View {
        FriendSearchBar(
            text: Binding(
                get: { store.state.query },
                set: { store.send(.queryChanged($0)) }
            ),
            isFocused: _isSearching,
            onClear: { store.send(.clearTapped) }
        )
        .padding(.horizontal, 16)
        .background(Color.white)
    }

    private var emptySearchView: some View {
        EmptyStateView(message: "친구를 검색해보세요")
            .frame(height: UIScreen.main.bounds.height - 300)
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
                    SearchEmptyView(keyword: store.state.query)
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
            TextField("검색", text: $text)
                .font(.system(size: 16))
                .foregroundColor(.gray1)
                .textInputAutocapitalization(.none)
                .disableAutocorrection(true)
                .focused($isFocused)
                .submitLabel(.search)

            if !text.isEmpty {
                Button {
                    onClear()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.gray2)
                }
            }

            Image(systemName: "magnifyingglass")
                .font(.system(size: 18))
                .foregroundColor(.gray2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(Color.gray5)
        )
    }
}

private struct FriendRowView: View {
    let people: People

    var body: some View {
        HStack(spacing: 12) {
            ProfileImageView(imageURL: people.profileImageURL, size: 52)

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


private struct SearchEmptyView: View {
    let keyword: String

    var body: some View {
        let subtitle = keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? nil
            : "\"\(keyword)\"에 대한 친구를 찾지 못했어요"

        EmptyStateView(message: "검색 결과가 없어요", subtitle: subtitle)
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
