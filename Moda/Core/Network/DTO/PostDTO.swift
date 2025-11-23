//
//  PostDTO.swift
//  Moda
//
//  Created by 금가경 on 11/16/24.
//

import Foundation

struct FileUploadResponse: Decodable {
    let files: [String]

    func toDomain() -> FileUploadResult {
        FileUploadResult(files: files)
    }
}

struct PostResponse: Decodable {
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
    let creator: PostCreator
    let files: [String]
    let likes: [String]
    let buyers: [String]
    let hashTags: [String]
    let commentCount: Int?
    let geolocation: PostGeolocation?
    let distance: Double?

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case category
        case title
        case price
        case content
        case value1
        case content2
        case content3
        case content4
        case content5
        case createdAt
        case creator
        case files
        case likes
        case buyers
        case hashTags
        case commentCount = "comment_count"
        case geolocation
        case distance
    }

    func toDomain() -> Post {
        Post(
            postId: postId,
            category: category,
            title: title,
            price: price,
            content: content,
            value1: value1,
            content2: content2,
            content3: content3,
            content4: content4,
            content5: content5,
            createdAt: createdAt,
            creator: creator.toDomain(),
            files: files,
            likes: likes,
            buyers: buyers,
            hashTags: hashTags,
            commentCount: commentCount,
            geolocation: geolocation?.toDomain(),
            distance: distance
        )
    }
}

struct PostCreator: Decodable {
    let userId: String
    let nick: String
    let profileImage: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nick
        case profileImage
    }

    func toDomain() -> PostCreatorModel {
        PostCreatorModel(
            userId: userId,
            nickname: nick,
            profileImage: profileImage
        )
    }
}

struct PostGeolocation: Decodable {
    let latitude: Double
    let longitude: Double

    func toDomain() -> PostGeolocationModel {
        PostGeolocationModel(
            latitude: latitude,
            longitude: longitude
        )
    }
}

struct PostListResponse: Decodable {
    let data: [PostResponse]
    let nextCursor: String

    enum CodingKeys: String, CodingKey {
        case data
        case nextCursor = "next_cursor"
    }

    func toDomain() -> PostListResult {
        PostListResult(
            posts: data.map { $0.toDomain() },
            nextCursor: nextCursor
        )
    }
}

struct LikeResponse: Decodable {
    let likeStatus: Bool

    enum CodingKeys: String, CodingKey {
        case likeStatus = "like_status"
    }

    func toDomain() -> LikeResult {
        LikeResult(likeStatus: likeStatus)
    }
}

struct GeolocationSearchResponse: Decodable {
    let data: [PostResponse]

    func toDomain() -> [Post] {
        data.map { $0.toDomain() }
    }
}

struct TitleSearchResponse: Decodable {
    let data: [PostResponse]

    func toDomain() -> [Post] {
        data.map { $0.toDomain() }
    }
}
