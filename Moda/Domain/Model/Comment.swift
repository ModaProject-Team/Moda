//
//  Comment.swift
//  Moda
//
//  Created by 금가경 on 11/16/24.
//

import Foundation

/// 앱 내부에서 사용하는 댓글 Domain Model
struct Comment {
    let commentId: String
    let content: String
    let createdAt: String
    let creator: CommentCreatorModel
    let replies: [Reply]?
}

/// 대댓글 모델
struct Reply {
    let commentId: String
    let content: String
    let createdAt: String
    let creator: CommentCreatorModel
}

/// 댓글 작성자 정보
struct CommentCreatorModel {
    let userId: String
    let nickname: String
    let profileImage: String?
}
