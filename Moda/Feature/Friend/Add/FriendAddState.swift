//
//  FriendAddState.swift
//  Moda
//
//  Created by 금가경 on 11/29/25.
//

import Foundation

struct FriendSearchItem: Identifiable, Hashable {
    let id: String
    let nickname: String
    let profileImageURL: URL?
    let statusMessage: String?
}

struct FriendAddState {
    var query: String = ""
    let maxLength: Int = 20

    var results: [FriendSearchItem] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var hasSearched: Bool = false

    var selectedItem: FriendSearchItem?
    var selectedIsFriend: Bool?
    var isFollowUpdating: Bool = false
}
