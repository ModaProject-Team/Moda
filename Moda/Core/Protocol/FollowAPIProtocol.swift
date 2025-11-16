//
//  FollowAPIProtocol.swift
//  Moda
//
//  Created by 금가경 on 11/16/24.
//

import Foundation

/// 팔로우 관련 API 프로토콜
protocol FollowAPIProtocol {
    /// 팔로우/언팔로우
    func follow(userId: String, followStatus: Bool) async throws -> FollowResponse
}
