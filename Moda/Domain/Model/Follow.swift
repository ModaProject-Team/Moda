//
//  Follow.swift
//  Moda
//
//  Created by 금가경 on 11/16/24.
//

import Foundation

/// 앱 내부에서 사용하는 팔로우 결과 Domain Model
struct FollowResult {
    let nick: String
    let opponentNick: String
    let followingStatus: Bool
}
