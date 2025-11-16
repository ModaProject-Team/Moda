//
//  FollowDTO.swift
//  Moda
//
//  Created by 금가경 on 11/16/24.
//

import Foundation

/// 팔로우 요청 바디
struct FollowRequest: Encodable {
    let followStatus: Bool

    enum CodingKeys: String, CodingKey {
        case followStatus = "follow_status"
    }
}

/// 팔로우 응답
struct FollowResponse: Decodable {
    let nick: String
    let opponentNick: String
    let followingStatus: Bool

    enum CodingKeys: String, CodingKey {
        case nick
        case opponentNick = "opponent_nick"
        case followingStatus = "following_status"
    }

    func toDomain() -> FollowResult {
        FollowResult(
            nick: nick,
            opponentNick: opponentNick,
            followingStatus: followingStatus
        )
    }
}
