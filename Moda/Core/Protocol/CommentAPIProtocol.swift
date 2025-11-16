//
//  CommentAPIProtocol.swift
//  Moda
//
//  Created by 금가경 on 11/16/24.
//

import Foundation

/// 댓글 관련 API 프로토콜
protocol CommentAPIProtocol {
    /// 댓글 목록 조회
    func getComments(postId: String) async throws -> CommentListResponse

    /// 댓글 작성
    func createComment(postId: String, content: String) async throws -> CommentResponse

    /// 댓글/대댓글 수정
    func updateComment(postId: String, commentId: String, content: String) async throws -> CommentResponse

    /// 댓글/대댓글 삭제
    func deleteComment(postId: String, commentId: String) async throws

    /// 대댓글 작성
    func createReply(postId: String, commentId: String, content: String) async throws -> ReplyResponse
}
