//
//  UserAPI.swift
//  Moda
//
//  Created by 금가경 on 11/12/24.
//

import Foundation

/// 사용자 관련 API 통신을 처리하는 클래스
///
/// 회원가입, 로그인, 로그아웃 등 사용자 인증 관련 API 호출을 제공합니다.
final class UserAPI: UserAPIProtocol {
    static let shared = UserAPI()

    private let networkService: NetworkServiceProtocol

    private init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
    }

    func validateEmail(email: String) async throws -> EmailValidationResponse {
        let endpoint = UserRouter.validateEmail(email: email)
        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: EmailValidationResponse.self
        )

        return response
    }

    func signUp(email: String, password: String, nickname: String) async throws -> SignUpResponse {
        let endpoint = UserRouter.signUp(
            email: email,
            password: password,
            nickname: nickname
        )

        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: SignUpResponse.self
        )

        return response
    }

    func login(email: String, password: String) async throws -> LoginResponse {
        let endpoint = UserRouter.login(email: email, password: password)
        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: LoginResponse.self
        )

        TokenManager.shared.saveToken(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )
        UserDefaultsManager.shared.userId = response.userId

        return response
    }

    // 서버 스펙: { "oauthToken": "<카카오 access token>" }
    func loginWithKakao(oauthToken: String) async throws -> LoginResponse {
        let endpoint = UserRouter.loginKakao(oauthToken: oauthToken)
        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: LoginResponse.self
        )

        TokenManager.shared.saveToken(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )
        UserDefaultsManager.shared.userId = response.userId

        return response
    }

    func loginWithApple(idToken: String) async throws -> LoginResponse {
        let endpoint = UserRouter.loginApple(idToken: idToken)
        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: LoginResponse.self
        )

        TokenManager.shared.saveToken(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )
        UserDefaultsManager.shared.userId = response.userId

        return response
    }

    func withdraw() async throws -> WithdrawResponse {
        let endpoint = UserRouter.withdraw
        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: WithdrawResponse.self
        )

        return response
    }

    func searchUsers(query: String) async throws -> UserSearchResponse {
        let endpoint = UserRouter.searchUsers(query: query)
        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: UserSearchResponse.self
        )

        return response
    }
}

