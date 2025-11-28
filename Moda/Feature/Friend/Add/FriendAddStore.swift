//
//  FriendAddStore.swift
//  Moda
//
//  Created by 금가경 on 11/29/25.
//

import SwiftUI
import Observation

@MainActor
@Observable
final class FriendAddStore {
    var state = FriendAddState()

    private let userAPI = UserAPI.shared
    private let userProfileAPI: UserProfileAPIProtocol = UserProfileAPI.shared
    private let followAPI = FollowAPI.shared

    private var searchTask: Task<Void, Never>?
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
        guard myUserId == nil else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                let me = try await userProfileAPI.getMyProfile()
                self.myUserId = me.userId
            } catch {
            }
        }
    }

    private func handleQueryChanged(_ text: String) {
        state.query = clampToMaxLength(text)
    }

    private func handleSearchSubmitted() {
        let trimmed = state.query.trimmingCharacters(in: .whitespacesAndNewlines)
        state.query = clampToMaxLength(trimmed)

        guard !state.query.isEmpty else { return }

        state.hasSearched = true

        searchTask?.cancel()

        state.selectedItem = nil
        state.selectedIsFriend = nil

        state.isLoading = true
        state.errorMessage = nil
        state.results = []

        let query = state.query

        searchTask = Task { [weak self] in
            guard let self else { return }
            do {
                let response = try await userAPI.searchUsers(query: query)

                if Task.isCancelled { return }

                var items: [FriendSearchItem] = response.data.map { dto in
                    FriendSearchItem(
                        id: dto.userId,
                        nickname: dto.nick,
                        profileImageURL: URL(string: "\(NetworkConfig.baseURL)/v1\(dto.profileImage ?? "")")
                    )
                }

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
        state.selectedItem = item
        state.selectedIsFriend = nil

        Task { [weak self] in
            guard let self else { return }
            do {
                let profile = try await userProfileAPI.getUserProfile(userId: item.id)
                if let myId = self.myUserId {
                    let isFriend = profile.followers.contains { $0.userId == myId }
                    state.selectedIsFriend = isFriend
                } else {
                    state.selectedIsFriend = false
                }
            } catch {
                if let netErr = error as? NetworkError {
                    state.errorMessage = netErr.localizedDescription
                } else {
                    state.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func handlefriendAddButtonTapped() {
        guard let selected = state.selectedItem, state.isFollowUpdating == false else { return }

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
