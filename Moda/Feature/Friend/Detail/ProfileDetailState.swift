//
//  ProfileDetailState.swift
//  Moda
//
//  Created by 금가경 on 11/29/25.
//

import Foundation

enum ProfileTab: String, CaseIterable, Identifiable {
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

struct ProfileDetailState {
    var isCurrentUser: Bool = true
    var userId: String

    var nickname: String = "닉네임"
    var profileImageURL: URL? = nil
    var selectedTab: ProfileTab = .myItems

    var userPosts: [PostCard] = []
    var likedPosts: [PostCard] = []

    var nextCursorUser: String = ""
    var nextCursorLiked: String = ""
    var hasMoreUser: Bool = true
    var hasMoreLiked: Bool = true

    var isLoading: Bool = false
    var errorMessage: String?

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
