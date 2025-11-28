//
//  FriendListStore.swift
//  Moda
//
//  Created by 금가경 on 11/29/25.
//

import SwiftUI
import Observation

@MainActor
@Observable
final class FriendListStore {
    private(set) var state = FriendListState()
    private let userProfileAPI: UserProfileAPIProtocol = UserProfileAPI.shared

    var myPeople: People? {
        guard let my = state.myProfile else { return nil }
        return People(
            id: my.userId,
            name: my.nick,
            statusMessage: my.info1,
            profileImageURL: URL(string: "\(NetworkConfig.baseURL)/v1\(my.profileImage ?? "")")
        )
    }

    var friendPeople: [People] {
        state.friends.map { friend in
            People(
                id: friend.userId,
                name: friend.nick,
                statusMessage: friend.info1,
                profileImageURL: URL(string: "\(NetworkConfig.baseURL)/v1\(friend.profileImage ?? "")")
            )
        }
    }

    func send(_ action: FriendListAction) {
        switch action {
        case .onAppear, .refresh:
            Task { await load() }
        case .dismissError:
            state.errorMessage = nil
        }
    }

    private func load() async {
        guard !state.isLoading else { return }
        state.isLoading = true
        defer { state.isLoading = false }

        do {
            let dto = try await userProfileAPI.getMyProfile()
            state.myProfile = dto

            let followerIDs = Set(dto.followers.map { $0.userId })
            let followingIDs = Set(dto.following.map { $0.userId })
            let mutualIDs = Array(followerIDs.intersection(followingIDs))

            var details: [OtherProfileResponse] = []
            for id in mutualIDs {
                do {
                    let profile = try await userProfileAPI.getUserProfile(userId: id)
                    details.append(profile)
                } catch {
                    continue
                }
            }

            state.friends = details.sorted {
                $0.nick.localizedCaseInsensitiveCompare($1.nick) == .orderedAscending
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
