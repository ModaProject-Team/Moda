//
//  CommentState.swift
//  Moda
//
//  Created by 금가경 on 11/29/25.
//

import Foundation

struct CommentState {
    var comments: [Comment] = []
    var inputText: String = ""
    var replyingToCommentId: String?
    var isLoading: Bool = false
    var isSending: Bool = false
    var errorMessage: String?
}
