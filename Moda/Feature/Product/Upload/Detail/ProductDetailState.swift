//
//  ProductDetailState.swift
//  Moda
//
//  Created by Suji Jang on 11/23/24.
//

import Foundation

struct ProductDetailState {
    var post: PostResponse?
    var isLoading = true
    var errorMessage: String?
    var showDeleteAlert = false
    var isDeleting = false
    var showActionSheet = false
    var isLiked = false
    var likeCount = 0

    var isMyPost: Bool {
        guard let post = post else { return false }
        let currentUserId = UserDefaultsManager.shared.userId ?? ""
        return post.creator.userId == currentUserId
    }
}
