//
//  CommentAPI.swift
//  Moda
//
//  Created by 금가경 on 11/16/24.
//

import Foundation

/// 댓글 관련 API 통신을 처리하는 클래스
///
/// 댓글 CRUD 및 대댓글 관련 API 호출을 제공합니다.
final class CommentAPI: CommentAPIProtocol {
    static let shared = CommentAPI()

    private let networkService: NetworkServiceProtocol

    private init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
    }

    func getComments(postId: String) async throws -> CommentListResponse {
        let endpoint = CommentRouter.getComments(postId: postId)
        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: CommentListResponse.self
        )

        return response
    }

    func createComment(postId: String, content: String) async throws -> CommentResponse {
        let endpoint = CommentRouter.createComment(postId: postId, content: content)
        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: CommentResponse.self
        )

        return response
    }

    func updateComment(postId: String, commentId: String, content: String) async throws -> CommentResponse {
        let endpoint = CommentRouter.updateComment(postId: postId, commentId: commentId, content: content)
        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: CommentResponse.self
        )

        return response
    }

    func deleteComment(postId: String, commentId: String) async throws {
        let endpoint = CommentRouter.deleteComment(postId: postId, commentId: commentId)
        try await networkService.requestWithoutResponse(endpoint: endpoint)
    }

    func createReply(postId: String, commentId: String, content: String) async throws -> ReplyResponse {
        let endpoint = CommentRouter.createReply(postId: postId, commentId: commentId, content: content)
        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: ReplyResponse.self
        )

        return response
    }
}
