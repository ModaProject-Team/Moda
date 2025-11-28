//
//  FriendAddView.swift
//  Moda
//
//  Created by hyunMac on 11/16/25.
//

import SwiftUI
import Observation

struct FriendAddView: View {
    @State private var store = FriendAddStore()
    @FocusState private var isSearching: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                searchBarSection

                if let selected = store.state.selectedItem {
                    selectedCardSection(selected: selected)
                } else {
                    resultsSection
                }
            }
        }
        .navigationTitle("닉네임으로 추가")
        .navigationBarTitleDisplayMode(.inline)
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
            store.send(.onAppear)
            try? await Task.sleep(for: .milliseconds(250))
            await MainActor.run {
                isSearching = true
            }
        }
    }

    private var searchBarSection: some View {
        FriendIDSearchBar(
            text: Binding(
                get: { store.state.query },
                set: { store.send(.queryChanged($0)) }
            ),
            isFocused: _isSearching,
            maxLength: store.state.maxLength,
            onSubmit: {
                store.send(.searchSubmitted)
                isSearching = false
            }, onClear: {
                store.send(.clearTapped)
            }
        )
    }

    private func selectedCardSection(selected: FriendSearchItem) -> some View {
        VStack {
            FriendSelectedCard(
                item: selected,
                isLoading: store.state.isFollowUpdating,
                buttonTitle: (store.state.selectedIsFriend == true) ? "친구 취소" : "친구 추가",
                onButtonTap: {
                    store.send(.friendAddButtonTapped)
                },
                onCloseTap: {
                    store.send(.cardCloseTapped)
                }
            )
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .frame(maxWidth: .infinity, maxHeight: 320, alignment: .top)

            Spacer()
        }
    }

    private var resultsSection: some View {
        Group {
            if store.state.isLoading {
                loadingSection
            } else if let message = store.state.errorMessage {
                errorSection(message: message)
            } else if !store.state.hasSearched {
                emptySearchSection
            } else if store.state.results.isEmpty {
                noResultsSection
            } else {
                searchResultsList
            }
        }
    }

    private var loadingSection: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView()
            Text("검색 중…")
                .Body1()
                .foregroundColor(.gray2)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorSection(message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.gray3)
            Text("오류가 발생했어요")
                .Body1()
                .foregroundColor(.gray2)
            Text(message)
                .Body2()
                .foregroundColor(.gray3)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptySearchSection: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "person.crop.circle.badge.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray3)
            Text("친구를 검색해 보세요")
                .Body1()
                .foregroundColor(.gray2)
            Text("닉네임을 입력하고 검색을 눌러보세요")
                .Body2()
                .foregroundColor(.gray3)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noResultsSection: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "person.fill.questionmark")
                .font(.system(size: 48))
                .foregroundColor(.gray3)
            Text("검색 결과가 없어요")
                .Body1()
                .foregroundColor(.gray2)
            Text("다른 닉네임으로 다시 시도해 보세요")
                .Body2()
                .foregroundColor(.gray3)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var searchResultsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(store.state.results) { item in
                    Button {
                        store.send(.rowTapped(item))
                        isSearching = false
                    } label: {
                        FriendRow(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 100)
        }
    }
}

private struct FriendIDSearchBar: View {
    @Binding var text: String
    @FocusState var isFocused: Bool
    let maxLength: Int
    let onSubmit: () -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                TextField("닉네임", text: $text)
                    .textInputAutocapitalization(.none)
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

private struct FriendSelectedCard: View {
    let item: FriendSearchItem
    let isLoading: Bool
    let buttonTitle: String
    let onButtonTap: () -> Void
    let onCloseTap: () -> Void

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(uiColor: .secondarySystemBackground))
            .overlay(
                VStack(spacing: 14) {
                    // 프로필 이미지
                    ProfileImageView(imageURL: item.profileImageURL, size: 72)

                    VStack(spacing: 4) {
                        Text(item.nickname)
                            .font(.headline)
                        Text("ID: \(item.id)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        onButtonTap()
                    } label: {
                        ZStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(buttonTitle)
                                    .font(.headline.weight(.semibold))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: 140)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.orange)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 12)
            )
            // 카드 우상단 X 버튼
            .overlay(alignment: .topTrailing) {
                Button {
                    onCloseTap()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(
                            Circle().fill(Color.black.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
                .padding(8) // 카드 모서리와 간격
            }
    }
}

private struct FriendRow: View {
    let item: FriendSearchItem

    var body: some View {
        HStack(spacing: 12) {
            ProfileImageView(imageURL: item.profileImageURL, size: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.nickname)
                    .H2()
                    .foregroundColor(.gray1)
                Text(item.id)
                    .Body2()
                    .foregroundColor(.gray2)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}


#Preview {
    NavigationStack {
        FriendAddView()
    }
}
