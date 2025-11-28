//
//  CommentIntent.swift
//  Moda
//
//  Created by 금가경 on 11/29/25.
//

import Foundation

enum CommentIntent {
    case loadComments
    case updateInputText(String)
    case sendComment
    case startReply(commentId: String)
    case cancelReply
    case deleteComment(commentId: String)
    case deleteReply(commentId: String, replyId: String)
}
