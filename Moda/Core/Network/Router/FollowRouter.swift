//
//  FollowRouter.swift
//  Moda
//
//  Created by 금가경 on 11/16/24.
//

import Foundation

/// 팔로우 관련 API 엔드포인트
enum FollowRouter {
    /// 팔로우/언팔로우
    case follow(userId: String, followStatus: Bool)
}

extension FollowRouter: Endpoint {
    var baseURL: String {
        return NetworkConfig.baseURL
    }

    var path: String {
        switch self {
        case .follow(let userId, _):
            return "/v1/follow/\(userId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .follow:
            return .post
        }
    }

    var headers: [String: String]? {
        var headers: [String: String] = [
            "Content-Type": "application/json",
            "SesacKey": NetworkConfig.sesacKey,
            "ProductId": NetworkConfig.productId
        ]

        if let accessToken = TokenManager.shared.accessToken {
            headers["Authorization"] = accessToken
        }

        return headers
    }

    var parameters: [String: Any]? {
        switch self {
        case .follow(_, let followStatus):
            return ["follow_status": followStatus]
        }
    }

    var queryItems: [URLQueryItem]? {
        return nil
    }
}
