//
//  SettingStore.swift
//  Moda
//
//  Created by Suji Jang on 11/24/24.
//

import SwiftUI

@MainActor
@Observable
final class SettingStore {
    var state = SettingState()

    private let userProfileAPI: UserProfileAPIProtocol
    private let postAPI: PostAPIProtocol
    private let userAPI: UserAPIProtocol
    private let userRealmService: UserRealmServiceProtocol

    init(
        userProfileAPI: UserProfileAPIProtocol = UserProfileAPI.shared,
        postAPI: PostAPIProtocol = PostAPI.shared,
        userAPI: UserAPIProtocol = UserAPI.shared,
        userRealmService: UserRealmServiceProtocol = UserRealmService.shared
    ) {
        self.userProfileAPI = userProfileAPI
        self.postAPI = postAPI
        self.userAPI = userAPI
        self.userRealmService = userRealmService
    }

    func send(_ intent: SettingIntent) {
        switch intent {
        case .onAppear:
            loadData()
        case .refresh:
            loadData()
        case .profileEditTapped, .likedPostsTapped, .logoutTapped:
            break
        case .withdrawTapped:
            Task { await withdraw() }
        }
    }

    private func loadData() {
        state.isLoading = true
        Task {
            // 로컬 프로필 먼저 로드
            await loadLocalProfile()

            do {
                let profile = try await userProfileAPI.getMyProfile()
                state.nickname = profile.nick

                if let profilePath = profile.profileImage,
                   let url = URL(string: NetworkConfig.baseURL + "/v1/" + profilePath) {
                    state.profileImageURL = url
                }

                // 서버에서 가져온 프로필 로컬에 저장
                await saveProfileToLocal(profile)

                let userId = UserDefaultsManager.shared.userId ?? ""
                let posts = try await postAPI.getUserPosts(
                    userId: userId,
                    next: nil,
                    limit: "1",
                    category: nil
                )

                if let firstPost = posts.data.first,
                   let firstFile = firstPost.files.first,
                   let url = URL(string: NetworkConfig.baseURL + "/v1/" + firstFile) {
                    state.latestPostImageURL = url
                }
            } catch {
                // 네트워크 오류 시 로컬 데이터 유지 (이미 loadLocalProfile에서 로드됨)
                // 오프라인일 때는 에러 메시지를 표시하지 않음
            }
            state.isLoading = false
        }
    }

    private func loadLocalProfile() async {
        if let profileData = await userRealmService.getMyProfileData() {
            state.localProfile = profileData
            state.nickname = profileData.nick
            if let profilePath = profileData.profileImage,
               let url = URL(string: NetworkConfig.baseURL + "/v1/" + profilePath) {
                state.profileImageURL = url
            }
        }
    }

    private func saveProfileToLocal(_ profile: MyProfileResponse) async {
        let userObject = UserObject.from(response: profile)
        try? await userRealmService.saveMyProfile(userObject)
        // Response에서 바로 생성 (Realm 객체 스레드 문제 방지)
        let profileData = UserProfileData(from: profile)
        state.localProfile = profileData
    }

    private func withdraw() async {
        state.isWithdrawing = true
        do {
            _ = try await userAPI.withdraw()

            TokenManager.shared.clearToken()
            UserDefaultsManager.shared.clearUserData()

            // 캐시 및 로컬 DB 정리
            await ImageCacheManager.shared.clearCache()
            await VideoCacheManager.shared.clearCache()

            // Realm 로컬 DB 삭제
            try? await userRealmService.deleteMyProfile()
            try? await FriendRealmService.shared.deleteAllFriends()
            try? await ChatRealmService.shared.deleteAllData()

            AppNavigator.shared.popToRoot()
            AppNavigator.shared.isLoggedIn = false
        } catch {
            state.errorMessage = error.localizedDescription
        }
        state.isWithdrawing = false
    }
}
