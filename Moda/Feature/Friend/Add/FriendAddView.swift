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
        .onTapGesture {
            hideKeyboard()
        }
        .navigationTitle("닉네임으로 추가")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackButton {
                    dismiss()
                }
            }
        }
        .enableSwipeBack()
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
            Image(systemName: "magnifyingglass")
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
            VStack(spacing: 0) {
                HStack {
                    Text("검색 결과 \(store.state.results.count)")
                        .Body2()
                        .foregroundColor(.gray2)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

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
            }
            .padding(.bottom, 100)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    hideKeyboard()
                }
        )
    }
}

private struct FriendIDSearchBar: View {
    @Binding var text: String
    @FocusState var isFocused: Bool
    let maxLength: Int
    let onSubmit: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            TextField("검색", text: $text)
                .font(.system(size: 16))
                .foregroundColor(.gray1)
                .textInputAutocapitalization(.none)
                .disableAutocorrection(true)
                .focused($isFocused)
                .submitLabel(.search)
                .onSubmit {
                    onSubmit()
                }

            if !text.isEmpty {
                Button {
                    text = ""
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
        .padding(.horizontal, 16)
        .background(Color.white)
    }
}

private struct FriendSelectedCard: View {
    let item: FriendSearchItem
    let isLoading: Bool
    let buttonTitle: String
    let onButtonTap: () -> Void
    let onCloseTap: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            ProfileImageView(imageURL: item.profileImageURL, size: 100)

            VStack(spacing: 8) {
                Text(item.nickname)
                    .H1()
                    .foregroundColor(.gray1)

                if let statusMessage = item.statusMessage, !statusMessage.isEmpty {
                    Text(statusMessage)
                        .Body2()
                        .foregroundColor(.gray2)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                } else {
                    Text("상태 메시지가 없습니다")
                        .Body2()
                        .foregroundColor(.gray3)
                }
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
                            .H2()
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue1)
                )
            }
            .disabled(isLoading)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
        .overlay(alignment: .topTrailing) {
            Button {
                onCloseTap()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray2)
                    .padding(8)
                    .background(
                        Circle().fill(Color.gray4)
                    )
            }
            .padding(12)
        }
    }
}

private struct FriendRow: View {
    let item: FriendSearchItem

    var body: some View {
        HStack(spacing: 14) {
            ProfileImageView(imageURL: item.profileImageURL, size: 56)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.nickname)
                    .H2()
                    .foregroundColor(.gray1)

                if let statusMessage = item.statusMessage, !statusMessage.isEmpty {
                    Text(statusMessage)
                        .Body2()
                        .foregroundColor(.gray2)
                        .lineLimit(1)
                } else {
                    Text("상태 메시지 없음")
                        .Body2()
                        .foregroundColor(.gray3)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.gray3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
    }
}


#Preview {
    NavigationStack {
        FriendAddView()
    }
}
