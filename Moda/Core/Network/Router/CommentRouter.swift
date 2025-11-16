//
//  CommentRouter.swift
//  Moda
//
//  Created by 금가경 on 11/16/24.
//

import Foundation

/// 댓글 관련 API 엔드포인트
enum CommentRouter {
    /// 댓글 목록 조회
    case getComments(postId: String)

    /// 댓글 작성
    case createComment(postId: String, content: String)

    /// 댓글/대댓글 수정
    case updateComment(postId: String, commentId: String, content: String)

    /// 댓글/대댓글 삭제
    case deleteComment(postId: String, commentId: String)

    /// 대댓글 작성
    case createReply(postId: String, commentId: String, content: String)
}

extension CommentRouter: Endpoint {
    var baseURL: String {
        return NetworkConfig.baseURL
    }

    var path: String {
        let basePath = "/v1/posts"

        switch self {
        case .getComments(let postId), .createComment(let postId, _):
            return "\(basePath)/\(postId)/comments"

        case .updateComment(let postId, let commentId, _), .deleteComment(let postId, let commentId):
            return "\(basePath)/\(postId)/comments/\(commentId)"

        case .createReply(let postId, let commentId, _):
            return "\(basePath)/\(postId)/comments/\(commentId)/replies"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getComments:
            return .get
        case .createComment, .createReply:
            return .post
        case .updateComment:
            return .put
        case .deleteComment:
            return .delete
        }
    }

    var headers: [String: String]? {
        var headers: [String: String] = [
            "Content-Type": "application/json",
            "SesacKey": NetworkConfig.sesacKey,
            "ProductId": NetworkConfig.productId
        ]

        if let accessToken = TokenManager.shared.accessToken {
            headers["Authorization"] = accessToken
        }

        return headers
    }

    var parameters: [String: Any]? {
        switch self {
        case .createComment(_, let content), .updateComment(_, _, let content), .createReply(_, _, let content):
            return ["content": content]
        default:
            return nil
        }
    }

    var queryItems: [URLQueryItem]? {
        return nil
    }
}
