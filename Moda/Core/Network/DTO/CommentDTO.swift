//
//  CommentDTO.swift
//  Moda
//
//  Created by 금가경 on 11/16/24.
//

import Foundation

struct CommentListResponse: Decodable {
    let data: [CommentResponse]

    func toDomain() -> [Comment] {
        data.map { $0.toDomain() }
    }
}

struct CommentResponse: Decodable {
    let commentId: String
    let content: String
    let createdAt: String
    let creator: CommentCreator
    let replies: [ReplyResponse]?

    enum CodingKeys: String, CodingKey {
        case commentId = "comment_id"
        case content
        case createdAt
        case creator
        case replies
    }

    func toDomain() -> Comment {
        Comment(
            commentId: commentId,
            content: content,
            createdAt: createdAt,
            creator: creator.toDomain(),
            replies: replies?.map { $0.toDomain() }
        )
    }
}

struct ReplyResponse: Decodable {
    let commentId: String
    let content: String
    let createdAt: String
    let creator: CommentCreator

    enum CodingKeys: String, CodingKey {
        case commentId = "comment_id"
        case content
        case createdAt
        case creator
    }

    func toDomain() -> Reply {
        Reply(
            commentId: commentId,
            content: content,
            createdAt: createdAt,
            creator: creator.toDomain()
        )
    }
}

struct CommentCreator: Decodable {
    let userId: String
    let nick: String
    let profileImage: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nick
        case profileImage
    }

    func toDomain() -> CommentCreatorModel {
        CommentCreatorModel(
            userId: userId,
            nickname: nick,
            profileImage: profileImage
        )
    }
}
