//
//  LikedPostsState.swift
//  Moda
//
//  Created by Suji Jang on 11/24/24.
//

import Foundation

struct LikedPostsState {
    var posts: [LikedPost] = []
    var nextCursor: String = ""
    var hasMore: Bool = true

    var isLoading: Bool = false
    var errorMessage: String? = nil
}

struct LikedPost: Identifiable {
    let id: String
    let title: String
    let price: Int
    let mediaURL: URL?
    let mediaPath: String? // 원본 파일 경로 (확장자 확인용)
    let profileImageURL: URL?
    let nickname: String
    var isLiked: Bool
}
