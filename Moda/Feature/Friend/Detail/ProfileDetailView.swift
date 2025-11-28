//
//  ProfileDetailView.swift
//  Moda
//
//  Created by hyunMac on 11/17/25.
//

import SwiftUI
import Observation
import Kingfisher
import Combine

private enum ProfileTab: String, CaseIterable, Identifiable {
    case myItems
    case likeItems

    var id: Self { self }

    var title: String {
        switch self {
        case .myItems: return "내 물건"
        case .likeItems: return "찜한 목록"
        }
    }
}

private struct ProfileDetailState {
    // 입력/환경
    var isCurrentUser: Bool = true
    var userId: String

    // 화면 상태
    var nickname: String = "닉네임"
    var profileImageURL: URL? = nil
    var selectedTab: ProfileTab = .myItems

    // 데이터
    var userPosts: [PostCard] = []
    var likedPosts: [PostCard] = []

    // 페이지네이션/로딩
    var nextCursorUser: String = ""
    var nextCursorLiked: String = ""
    var hasMoreUser: Bool = true
    var hasMoreLiked: Bool = true

    var isLoading: Bool = false
    var errorMessage: String?

    // 편의
    var currentList: [PostCard] {
        if isCurrentUser {
            return selectedTab == .myItems ? userPosts : likedPosts
        } else {
            return userPosts
        }
    }

    init(
        userId: String,
        isCurrentUser: Bool = true,
        nickname: String = "닉네임",
        profileImageURL: URL? = nil,
        selectedTab: ProfileTab = .myItems
    ) {
        self.userId = userId
        self.isCurrentUser = isCurrentUser
        self.nickname = nickname
        self.profileImageURL = profileImageURL
        self.selectedTab = selectedTab
    }
}

private enum ProfileDetailIntent {
    case onAppear
    case selectTab(ProfileTab)
    case editTapped
    case uploadTapped

    case loadMore
    case refresh
    case toggleLike(String)
}

@MainActor
@Observable
private final class ProfileDetailStore {

    var state: ProfileDetailState

    // API
    private let postAPI: PostAPIProtocol

    // Combine for debounced like
    private var cancellables = Set<AnyCancellable>()
    private let likeSubject = PassthroughSubject<String, Never>()
    private var pendingLikeStates: [String: Bool] = [:]

    init(initial: ProfileDetailState, postAPI: PostAPIProtocol = PostAPI.shared) {
        self.state = initial
        self.postAPI = postAPI
        setupCombine()
    }

    func send(_ intent: ProfileDetailIntent) {
        switch intent {
        case .onAppear:
            handleOnAppear()

        case .selectTab(let tab):
            handleSelectTab(tab)

        case .editTapped:
            handleEditTapped()

        case .uploadTapped:
            handleUploadTapped()

        case .loadMore:
            handleLoadMore()

        case .refresh:
            handleRefresh()

        case .toggleLike(let postId):
            toggleLikeWithDebounce(postId: postId)
        }
    }

    private func setupCombine() {
        likeSubject
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] postId in
                Task { @MainActor in
                    await self?.sendLikeRequest(postId: postId)
                }
            }
            .store(in: &cancellables)
    }

    private func handleOnAppear() {
        // 초기에는 사용자 게시글 로드
        if state.userPosts.isEmpty {
            Task { await fetchUserPosts(refresh: true) }
        }
    }

    private func handleSelectTab(_ tab: ProfileTab) {
        state.selectedTab = tab
        if state.isCurrentUser && tab == .likeItems && state.likedPosts.isEmpty {
            Task { await fetchLikedPosts(refresh: true) }
        }
    }

    private func handleEditTapped() {
        print("수정 버튼 탭")
    }

    private func handleUploadTapped() {
        print("물건 올리기 버튼 탭")
    }

    private func handleLoadMore() {
        guard !state.isLoading else { return }

        if state.isCurrentUser && state.selectedTab == .likeItems {
            guard state.hasMoreLiked else { return }
            Task { await fetchLikedPosts(refresh: false) }
        } else {
            guard state.hasMoreUser else { return }
            Task { await fetchUserPosts(refresh: false) }
        }
    }

    private func handleRefresh() {
        if state.isCurrentUser && state.selectedTab == .likeItems {
            Task { await fetchLikedPosts(refresh: true) }
        } else {
            Task { await fetchUserPosts(refresh: true) }
        }
    }

    private func fetchUserPosts(refresh: Bool) async {
        if refresh {
            state.nextCursorUser = ""
            state.hasMoreUser = true
        }
        guard state.hasMoreUser else { return }

        state.isLoading = true
        state.errorMessage = nil

        do {
            let cursor = refresh ? nil : (state.nextCursorUser.isEmpty ? nil : state.nextCursorUser)
            let response = try await postAPI.getUserPosts(
                userId: state.userId,
                next: cursor,
                limit: "20",
                category: nil
            )

            let currentUserId = UserDefaults.standard.string(forKey: "userId")
            var newPosts = response.data.map { $0.toDomain().toPostCard(currentUserId: currentUserId) }

            // 최신순 정렬
            newPosts.sort { $0.createdAt > $1.createdAt }

            if refresh {
                state.userPosts = newPosts
            } else {
                let existingIds = Set(state.userPosts.map { $0.id })
                let unique = newPosts.filter { !existingIds.contains($0.id) }
                state.userPosts.append(contentsOf: unique)
            }

            state.nextCursorUser = response.nextCursor
            state.hasMoreUser = !response.nextCursor.isEmpty && response.nextCursor != "0"
        } catch {
            state.errorMessage = error.localizedDescription
            print("사용자 게시글 로드 실패: \(error.localizedDescription)")
        }

        state.isLoading = false
    }

    private func fetchLikedPosts(refresh: Bool) async {
        if refresh {
            state.nextCursorLiked = ""
            state.hasMoreLiked = true
        }
        guard state.hasMoreLiked else { return }

        state.isLoading = true
        state.errorMessage = nil

        do {
            let cursor = refresh ? nil : (state.nextCursorLiked.isEmpty ? nil : state.nextCursorLiked)
            let response = try await postAPI.getMyLikedPosts(
                next: cursor,
                limit: "20",
                category: nil
            )

            let currentUserId = UserDefaults.standard.string(forKey: "userId")
            var newPosts = response.data.map { $0.toDomain().toPostCard(currentUserId: currentUserId) }
            newPosts.sort { $0.createdAt > $1.createdAt }

            if refresh {
                state.likedPosts = newPosts
            } else {
                let existingIds = Set(state.likedPosts.map { $0.id })
                let unique = newPosts.filter { !existingIds.contains($0.id) }
                state.likedPosts.append(contentsOf: unique)
            }

            state.nextCursorLiked = response.nextCursor
            state.hasMoreLiked = !response.nextCursor.isEmpty && response.nextCursor != "0"
        } catch {
            state.errorMessage = error.localizedDescription
            print("찜한 게시글 로드 실패: \(error.localizedDescription)")
        }

        state.isLoading = false
    }

    private func toggleLikeWithDebounce(postId: String) {
        // 현재 탭 기준으로 먼저 UI 반영
        updateLikeUI(postId: postId) { newState in
            pendingLikeStates[postId] = newState
            likeSubject.send(postId)
        }
    }

    private func updateLikeUI(postId: String, completion: (Bool) -> Void) {
        // userPosts
        if let idx = state.userPosts.firstIndex(where: { $0.id == postId }) {
            state.userPosts[idx].isLiked.toggle()
            let newState = state.userPosts[idx].isLiked
            if newState {
                state.userPosts[idx].likeCount += 1
            } else {
                state.userPosts[idx].likeCount = max(0, state.userPosts[idx].likeCount - 1)
            }
            completion(newState)
            // liked 탭에서도 동일 id가 있으면 동기화
            if let lidx = state.likedPosts.firstIndex(where: { $0.id == postId }) {
                state.likedPosts[lidx].isLiked = state.userPosts[idx].isLiked
                state.likedPosts[lidx].likeCount = state.userPosts[idx].likeCount
            }
            return
        }

        // likedPosts
        if let idx = state.likedPosts.firstIndex(where: { $0.id == postId }) {
            state.likedPosts[idx].isLiked.toggle()
            let newState = state.likedPosts[idx].isLiked
            if newState {
                state.likedPosts[idx].likeCount += 1
            } else {
                state.likedPosts[idx].likeCount = max(0, state.likedPosts[idx].likeCount - 1)
            }
            completion(newState)
            // user 탭에서도 동일 id가 있으면 동기화
            if let uidx = state.userPosts.firstIndex(where: { $0.id == postId }) {
                state.userPosts[uidx].isLiked = state.likedPosts[idx].isLiked
                state.userPosts[uidx].likeCount = state.likedPosts[idx].likeCount
            }
            return
        }
    }

    private func sendLikeRequest(postId: String) async {
        guard let likeStatus = pendingLikeStates[postId] else { return }
        do {
            _ = try await postAPI.likePost(postId: postId, likeStatus: likeStatus)
            pendingLikeStates.removeValue(forKey: postId)
        } catch {
            // 실패 시 롤백
            rollbackLikeUI(postId: postId)
            print("좋아요 요청 실패: \(error.localizedDescription)")
        }
    }

    private func rollbackLikeUI(postId: String) {
        if let idx = state.userPosts.firstIndex(where: { $0.id == postId }) {
            state.userPosts[idx].isLiked.toggle()
            if state.userPosts[idx].isLiked {
                state.userPosts[idx].likeCount += 1
            } else {
                state.userPosts[idx].likeCount = max(0, state.userPosts[idx].likeCount - 1)
            }
        }
        if let idx = state.likedPosts.firstIndex(where: { $0.id == postId }) {
            state.likedPosts[idx].isLiked.toggle()
            if state.likedPosts[idx].isLiked {
                state.likedPosts[idx].likeCount += 1
            } else {
                state.likedPosts[idx].likeCount = max(0, state.likedPosts[idx].likeCount - 1)
            }
        }
    }
}

struct ProfileDetailView: View {
    @State private var store: ProfileDetailStore
    @EnvironmentObject var navigator: AppNavigator

    init(people: People, isCurrentUser: Bool) {
        let initial = ProfileDetailState(
            userId: people.id,
            isCurrentUser: isCurrentUser,
            nickname: people.name,
            profileImageURL: people.profileImageURL
        )
        _store = State(initialValue: ProfileDetailStore(initial: initial))
    }

    var body: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 12
            let horizontalPadding: CGFloat = 16
            let itemWidth = (geometry.size.width - horizontalPadding * 2 - spacing) / 2

            ZStack {
                Color.white.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        header

                        if store.state.isCurrentUser {
                            segment
                        }

                        ProductGridView(
                            products: store.state.currentList,
                            itemWidth: itemWidth,
                            spacing: spacing,
                            horizontalPadding: horizontalPadding,
                            currentLocation: nil,
                            isLoading: store.state.isLoading,
                            emptyMessage: store.state.isCurrentUser && store.state.selectedTab == .likeItems ? "찜한 물건이 없어요" : "등록된 물건이 없어요",
                            onLikeTapped: { postId in
                                store.send(.toggleLike(postId))
                            },
                            onProductTapped: { postId in
                                navigator.push(.productDetail(postId: postId))
                            },
                            onLoadMore: {
                                store.send(.loadMore)
                            }
                        )
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 80)
                }
                .refreshable {
                    store.send(.refresh)
                }

                if store.state.isLoading && store.state.currentList.isEmpty {
                    ProgressView()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    navigator.pop()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.gray1)
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if store.state.isCurrentUser {
                FloatingUploadButton(title: "물건 올리기") {
                    store.send(.uploadTapped)
                }
                .padding(.trailing, 16)
                .padding(.bottom, 24)
            }
        }
        .task { store.send(.onAppear) }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Group {
                if let url = store.state.profileImageURL {
                    KFImage(url)
                        .requestModifier(KFHeaders.modifier)
                        .placeholder {
                            Circle().fill(Color.gray3)
                        }
                        .cacheOriginalImage()
                        .fade(duration: 0.2)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipShape(Circle())
                } else {
                    ZStack {
                        Circle().fill(Color.gray3)
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    }
                    .frame(width: 72, height: 72)
                }
            }

            Text(store.state.nickname)
                .H2()
                .foregroundColor(.gray1)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var segment: some View {
        Picker("", selection: Binding(
            get: { store.state.selectedTab },
            set: { store.send(.selectTab($0)) }
        )) {
            ForEach(ProfileTab.allCases) { tab in
                Text(tab.title).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
    }

}

private struct FloatingUploadButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Text(title)
                    .H2()
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(Color.blue1)
            )
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    NavigationStack {
        VStack(spacing: 12) {
            ProfileDetailView(
                people: People(id: "me", name: "나의 닉네임", statusMessage: "상태메시지", profileImageURL: nil),
                isCurrentUser: true
            )
            .navigationTitle("프로필")
        }
    }
}
