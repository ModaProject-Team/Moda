//
//  CommentStore.swift
//  Moda
//
//  Created by 금가경 on 11/29/25.
//

import SwiftUI

@MainActor
final class CommentStore: ObservableObject {
    @Published private(set) var state = CommentState()

    private let postId: String
    private let commentAPI: CommentAPIProtocol

    init(postId: String, commentAPI: CommentAPIProtocol = CommentAPI.shared) {
        self.postId = postId
        self.commentAPI = commentAPI
    }

    func send(_ intent: CommentIntent) {
        switch intent {
        case .loadComments:
            Task { await loadComments() }

        case .updateInputText(let text):
            state.inputText = text

        case .sendComment:
            Task { await sendComment() }

        case .startReply(let commentId):
            state.replyingToCommentId = commentId

        case .cancelReply:
            state.replyingToCommentId = nil

        case .deleteComment(let commentId):
            Task { await deleteComment(commentId: commentId) }

        case .deleteReply(let commentId, let replyId):
            Task { await deleteReply(commentId: commentId, replyId: replyId) }
        }
    }

    private func loadComments() async {
        state.isLoading = true

        do {
            let response = try await commentAPI.getComments(postId: postId)
            state.comments = response.toDomain()
            state.isLoading = false
        } catch {
            state.errorMessage = "댓글을 불러오는데 실패했습니다"
            state.isLoading = false
        }
    }

    private func sendComment() async {
        guard !state.inputText.isEmpty else { return }

        state.isSending = true
        let content = state.inputText

        do {
            if let replyingTo = state.replyingToCommentId {
                _ = try await commentAPI.createReply(postId: postId, commentId: replyingTo, content: content)
                state.replyingToCommentId = nil
            } else {
                _ = try await commentAPI.createComment(postId: postId, content: content)
            }

            state.inputText = ""
            state.isSending = false
            await loadComments()
            NotificationCenter.default.post(name: NSNotification.Name("commentUpdated"), object: nil)
        } catch {
            state.errorMessage = "댓글 작성에 실패했습니다"
            state.isSending = false
        }
    }

    private func deleteComment(commentId: String) async {
        do {
            try await commentAPI.deleteComment(postId: postId, commentId: commentId)
            await loadComments()
            NotificationCenter.default.post(name: NSNotification.Name("commentUpdated"), object: nil)
        } catch {
            state.errorMessage = "댓글 삭제에 실패했습니다"
        }
    }

    private func deleteReply(commentId: String, replyId: String) async {
        do {
            try await commentAPI.deleteComment(postId: postId, commentId: replyId)
            await loadComments()
            NotificationCenter.default.post(name: NSNotification.Name("commentUpdated"), object: nil)
        } catch {
            state.errorMessage = "답글 삭제에 실패했습니다"
        }
    }
}
