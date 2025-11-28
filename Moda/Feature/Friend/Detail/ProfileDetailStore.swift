//
//  ProfileDetailStore.swift
//  Moda
//
//  Created by 금가경 on 11/29/25.
//

import SwiftUI
import Observation
import Combine

@MainActor
@Observable
final class ProfileDetailStore {

    var state: ProfileDetailState

    private let postAPI: PostAPIProtocol

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
    }

    private func handleUploadTapped() {
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

            let currentUserId = UserDefaultsManager.shared.userId
            var newPosts = response.data.map { $0.toDomain().toPostCard(currentUserId: currentUserId) }

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

            let currentUserId = UserDefaultsManager.shared.userId
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
        }

        state.isLoading = false
    }

    private func toggleLikeWithDebounce(postId: String) {
        updateLikeUI(postId: postId) { newState in
            pendingLikeStates[postId] = newState
            likeSubject.send(postId)
        }
    }

    private func updateLikeUI(postId: String, completion: (Bool) -> Void) {
        if let idx = state.userPosts.firstIndex(where: { $0.id == postId }) {
            state.userPosts[idx].isLiked.toggle()
            let newState = state.userPosts[idx].isLiked
            if newState {
                state.userPosts[idx].likeCount += 1
            } else {
                state.userPosts[idx].likeCount = max(0, state.userPosts[idx].likeCount - 1)
            }
            completion(newState)
            if let lidx = state.likedPosts.firstIndex(where: { $0.id == postId }) {
                state.likedPosts[lidx].isLiked = state.userPosts[idx].isLiked
                state.likedPosts[lidx].likeCount = state.userPosts[idx].likeCount
            }
            return
        }

        if let idx = state.likedPosts.firstIndex(where: { $0.id == postId }) {
            state.likedPosts[idx].isLiked.toggle()
            let newState = state.likedPosts[idx].isLiked
            if newState {
                state.likedPosts[idx].likeCount += 1
            } else {
                state.likedPosts[idx].likeCount = max(0, state.likedPosts[idx].likeCount - 1)
            }
            completion(newState)
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
            rollbackLikeUI(postId: postId)
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
