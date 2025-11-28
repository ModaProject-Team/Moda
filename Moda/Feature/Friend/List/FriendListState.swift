//
//  FriendListState.swift
//  Moda
//
//  Created by 금가경 on 11/29/25.
//

import Foundation

struct People: Identifiable, Hashable {
    let id: String
    var name: String
    var statusMessage: String?
    var profileImageURL: URL?
}

struct FriendListState {
    var myProfile: MyProfileResponse?
    var friends: [OtherProfileResponse] = []
    var isLoading: Bool = false
    var errorMessage: String?
}
