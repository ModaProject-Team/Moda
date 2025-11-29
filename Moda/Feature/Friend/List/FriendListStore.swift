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
    private let friendRealmService: FriendRealmServiceProtocol = FriendRealmService.shared
    private let userRealmService: UserRealmServiceProtocol = UserRealmService.shared

    var myPeople: People? {
        // 로컬 프로필 우선, 없으면 서버 프로필 사용
        if let local = state.localMyProfile {
            return People(
                id: local.userId,
                name: local.nick,
                statusMessage: local.info1,
                profileImageURL: URL(string: "\(NetworkConfig.baseURL)/v1\(local.profileImage ?? "")")
            )
        } else if let my = state.myProfile {
            return People(
                id: my.userId,
                name: my.nick,
                statusMessage: my.info1,
                profileImageURL: URL(string: "\(NetworkConfig.baseURL)/v1\(my.profileImage ?? "")")
            )
        }
        return nil
    }

    var friendPeople: [People] {
        // 서버 친구 목록 우선, 없으면 로컬 친구 목록 사용
        if !state.friends.isEmpty {
            return state.friends.map { friend in
                People(
                    id: friend.userId,
                    name: friend.nick,
                    statusMessage: friend.info1,
                    profileImageURL: URL(string: "\(NetworkConfig.baseURL)/v1\(friend.profileImage ?? "")")
                )
            }
        } else {
            return state.localFriends.map { friend in
                People(
                    id: friend.userId,
                    name: friend.nick,
                    statusMessage: friend.info1,
                    profileImageURL: URL(string: "\(NetworkConfig.baseURL)/v1\(friend.profileImage ?? "")")
                )
            }
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

        // 로컬 프로필 먼저 로드
        await loadLocalMyProfile()

        // 로컬 친구 목록 먼저 로드
        await loadLocalFriends()

        // 서버 동기화 시도
        do {
            let dto = try await userProfileAPI.getMyProfile()
            state.myProfile = dto

            // 서버에서 가져온 내 프로필 로컬에 저장
            await saveMyProfileToLocal(dto)

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

            // 서버에서 가져온 친구 목록 로컬에 저장
            await saveFriendsToLocal(details)

        } catch {
            // 네트워크 오류 시 로컬 데이터로 유지 (이미 loadLocalMyProfile, loadLocalFriends에서 로드됨)
            // 오프라인일 때는 에러 메시지를 표시하지 않음
        }
    }

    private func loadLocalMyProfile() async {
        if let profileData = await userRealmService.getMyProfileData() {
            state.localMyProfile = profileData
        }
    }

    private func loadLocalFriends() async {
        let friendsData = await friendRealmService.getAllFriendsData()
        state.localFriends = friendsData
    }

    private func saveMyProfileToLocal(_ profile: MyProfileResponse) async {
        let userObject = UserObject.from(response: profile)
        try? await userRealmService.saveMyProfile(userObject)
        // Response에서 바로 생성 (Realm 객체 스레드 문제 방지)
        let profileData = UserProfileData(from: profile)
        state.localMyProfile = profileData
    }

    private func saveFriendsToLocal(_ friends: [OtherProfileResponse]) async {
        let friendObjects = friends.map { FriendObject.from(response: $0) }
        try? await friendRealmService.saveFriends(friendObjects)
        // Response에서 바로 생성 (Realm 객체 스레드 문제 방지)
        let friendsData = friends.map { FriendData(from: $0) }
        state.localFriends = friendsData
    }
}
