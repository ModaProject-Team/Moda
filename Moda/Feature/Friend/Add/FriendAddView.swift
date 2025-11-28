//
//  FriendAddView.swift
//  Moda
//
//  Created by hyunMac on 11/16/25.
//

import SwiftUI
import Observation

private struct FriendSearchItem: Identifiable, Hashable {
    let id: String          // userId
    let nickname: String    // nick
    let profileImageURL: URL?
}

private struct FriendAddState {
    var query: String = ""
    let maxLength: Int = 20

    // 검색 관련 상태
    var results: [FriendSearchItem] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var hasSearched: Bool = false // 첫 검색 여부

    // 선택된 셀(선택 시 목록 숨기고 카드만 노출)
    var selectedItem: FriendSearchItem?

    // 선택된 항목의 "친구 여부"
    // true: 이미 내가 팔로우 중 → 버튼은 "친구 취소"
    // false 또는 nil: 팔로우 아님(또는 미확정) → 버튼은 "친구 추가"
    var selectedIsFriend: Bool?

    // 팔로우/언팔로우 진행 상태
    var isFollowUpdating: Bool = false
}


private enum FriendAddIntent {
    case onAppear
    case queryChanged(String)
    case clearTapped
    case searchSubmitted
    case rowTapped(FriendSearchItem)

    // 카드 친구 추가/취소 버튼 탭
    case friendAddButtonTapped

    // 카드 닫기(X) 버튼 탭
    case cardCloseTapped
}

@MainActor
@Observable
private final class FriendAddStore {
    var state = FriendAddState()

    // 의존성
    private let userAPI = UserAPI.shared
    private let userProfileAPI: UserProfileAPIProtocol = UserProfileAPI.shared
    private let followAPI = FollowAPI.shared

    // 동시 검색 취소용
    private var searchTask: Task<Void, Never>?

    // 내 사용자 ID
    private var myUserId: String?

    func send(_ intent: FriendAddIntent) {
        switch intent {
        case .onAppear:
            handleOnAppear()
        case .queryChanged(let text):
            handleQueryChanged(text)
        case .clearTapped:
            state.query = ""
        case .searchSubmitted:
            handleSearchSubmitted()
        case .rowTapped(let item):
            handleRowTapped(item)
        case .friendAddButtonTapped:
            handlefriendAddButtonTapped()
        case .cardCloseTapped:
            handleCardCloseTapped()
        }
    }

    private func handleOnAppear() {
        // 최초 1회 내 프로필 로드(내 userId 확보)
        guard myUserId == nil else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                let me = try await userProfileAPI.getMyProfile()
                self.myUserId = me.userId
            } catch {
                // 내 ID 로드 실패는 치명적이지 않으므로 로그만
                print("친구 추가 뷰, 내 프로필 불러오지 못함:", error.localizedDescription)
            }
        }
    }

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

        // 선택 상태 초기화(새 검색 시작 시 카드 숨김)
        state.selectedItem = nil
        state.selectedIsFriend = nil

        // 로딩 시작
        state.isLoading = true
        state.errorMessage = nil
        state.results = []

        let query = state.query

        // 실제 네트워크 검색
        searchTask = Task { [weak self] in
            guard let self else { return }
            do {
                let response = try await userAPI.searchUsers(query: query)

                // 취소되었으면 중단
                if Task.isCancelled { return }

                // FriendListView 방식으로 단순 URL 생성
                var items: [FriendSearchItem] = response.data.map { dto in
                    FriendSearchItem(
                        id: dto.userId,
                        nickname: dto.nick,
                        profileImageURL: URL(string: "\(NetworkConfig.baseURL)/v1\(dto.profileImage ?? "")")
                    )
                }

                // 내 아이디 제외
                if let myId = self.myUserId {
                    items.removeAll { $0.id == myId }
                }

                state.results = items
            } catch {
                if let netErr = error as? NetworkError {
                    state.errorMessage = netErr.localizedDescription
                } else {
                    state.errorMessage = error.localizedDescription
                }
            }
            state.isLoading = false
        }
    }

    private func handleRowTapped(_ item: FriendSearchItem) {
        // 선택된 셀로 카드 표시
        state.selectedItem = item
        state.selectedIsFriend = nil // 아직 모르는 상태(nil) → 버튼은 "친구 추가"로 노출

        // 선택한 유저의 상세 프로필 조회하여 followers에 내 ID가 있는지 확인
        Task { [weak self] in
            guard let self else { return }
            do {
                let profile = try await userProfileAPI.getUserProfile(userId: item.id)
                if let myId = self.myUserId {
                    let isFriend = profile.followers.contains { $0.userId == myId }
                    state.selectedIsFriend = isFriend
                } else {
                    // 내 ID를 모르면 판단 불가 → 기본 false
                    state.selectedIsFriend = false
                }
            } catch {
                if let netErr = error as? NetworkError {
                    state.errorMessage = netErr.localizedDescription
                } else {
                    state.errorMessage = error.localizedDescription
                }
                // 판단 실패 시 기본값 유지
            }
        }
    }

    private func handlefriendAddButtonTapped() {
        guard let selected = state.selectedItem, state.isFollowUpdating == false else { return }

        // 현재 상태 반대로 요청
        let shouldFollow = !(state.selectedIsFriend ?? false)
        state.isFollowUpdating = true

        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await followAPI.follow(userId: selected.id, followStatus: shouldFollow)
                state.selectedIsFriend = shouldFollow
            } catch {
                if let netErr = error as? NetworkError {
                    state.errorMessage = netErr.localizedDescription
                } else {
                    state.errorMessage = error.localizedDescription
                }
            }
            state.isFollowUpdating = false
        }
    }

    private func handleCardCloseTapped() {
        // 카드 닫기: 선택 해제 → 기존 검색 결과 리스트 노출
        state.selectedItem = nil
        state.selectedIsFriend = nil
        state.isFollowUpdating = false
    }

    private func clampToMaxLength(_ text: String) -> String {
        if text.count > state.maxLength {
            return String(text.prefix(state.maxLength))
        } else {
            return text
        }
    }
}

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
