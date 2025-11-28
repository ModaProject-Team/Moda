//
//  Post.swift
//  Moda
//
//  Created by 금가경 on 11/16/24.
//

import Foundation

/// 앱 내부에서 사용하는 게시글 Domain Model
struct Post: Identifiable {
    var id: String { postId }

    let postId: String
    let category: String
    let title: String
    let price: Int?
    let content: String?
    let value1: String?
    let content2: String?
    let content3: String?
    let content4: String?
    let content5: String?
    let createdAt: String
    let creator: PostCreatorModel
    let files: [String]
    let likes: [String]
    let buyers: [String]
    let hashTags: [String]
    let commentCount: Int?
    let geolocation: PostGeolocationModel?
    let distance: Double?
}

/// 게시글 작성자 정보
struct PostCreatorModel {
    let userId: String
    let nickname: String
    let profileImage: String?
}

/// 게시글 위치 정보
struct PostGeolocationModel {
    let latitude: Double
    let longitude: Double
}

/// 파일 업로드 결과
struct FileUploadResult {
    let files: [String]
}

/// 게시글 목록 결과
struct PostListResult {
    let posts: [Post]
    let nextCursor: String
}

/// 좋아요 결과
struct LikeResult {
    let likeStatus: Bool
}
