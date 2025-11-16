//
//  FollowAPI.swift
//  Moda
//
//  Created by 금가경 on 11/16/24.
//

import Foundation

/// 팔로우 관련 API 통신을 처리하는 클래스
///
/// 팔로우/언팔로우 API 호출을 제공합니다.
final class FollowAPI: FollowAPIProtocol {
    static let shared = FollowAPI()

    private let networkService: NetworkServiceProtocol

    private init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
    }

    func follow(userId: String, followStatus: Bool) async throws -> FollowResponse {
        let endpoint = FollowRouter.follow(userId: userId, followStatus: followStatus)
        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: FollowResponse.self
        )

        return response
    }
}
