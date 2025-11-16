//
//  AuthAPI.swift
//  Moda
//
//  Created by 금가경 on 11/14/24.
//

import Foundation

/// 인증 토큰 관련 API 통신을 처리하는 클래스
///
/// 토큰 갱신 등 인증 토큰 관련 서버 API 호출을 제공합니다.
final class AuthAPI: AuthAPIProtocol {
    static let shared = AuthAPI()

    private let networkService: NetworkServiceProtocol

    private init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
    }

    func refreshToken() async throws -> RefreshTokenResponse {
        let endpoint = AuthRouter.refreshToken
        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: RefreshTokenResponse.self
        )

        TokenManager.shared.saveToken(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )

        return response
    }
}
