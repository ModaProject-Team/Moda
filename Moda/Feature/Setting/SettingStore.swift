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

    init(
        userProfileAPI: UserProfileAPIProtocol = UserProfileAPI.shared,
        postAPI: PostAPIProtocol = PostAPI.shared
    ) {
        self.userProfileAPI = userProfileAPI
        self.postAPI = postAPI
    }

    func send(_ intent: SettingIntent) {
        switch intent {
        case .onAppear:
            loadData()
        case .refresh:
            loadData()
        case .profileEditTapped, .likedPostsTapped, .logoutTapped:
            break
        }
    }

    private func loadData() {
        state.isLoading = true
        Task {
            do {
                let profile = try await userProfileAPI.getMyProfile()
                state.nickname = profile.nick

                if let profilePath = profile.profileImage,
                   let url = URL(string: NetworkConfig.baseURL + "/v1/" + profilePath) {
                    state.profileImageURL = url
                }

                let userId = UserDefaults.standard.string(forKey: "userId") ?? ""
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
                state.errorMessage = error.localizedDescription
            }
            state.isLoading = false
        }
    }
}
