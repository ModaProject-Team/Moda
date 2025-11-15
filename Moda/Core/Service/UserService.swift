//
//  UserService.swift
//  Moda
//
//  Created by 금가경 on 11/12/24.
//

import Foundation

/// 사용자 관련 비즈니스 로직을 처리하는 서비스
///
/// 회원가입, 로그인, 로그아웃 등 사용자 인증 관련 기능을 제공합니다.
final class UserService: UserServiceProtocol {
    static let shared = UserService()

    private let networkService: NetworkServiceProtocol

    private init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
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

        return response
    }

    func loginWithKakao(idToken: String) async throws -> LoginResponse {
        let endpoint = UserRouter.loginKakao(token: idToken)
        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: LoginResponse.self
        )

        TokenManager.shared.saveToken(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )

        return response
    }

    func loginWithApple(idToken: String) async throws -> LoginResponse {
        let endpoint = UserRouter.loginApple(token: idToken)
        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: LoginResponse.self
        )

        TokenManager.shared.saveToken(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )

        return response
    }

    func logout() {
        TokenManager.shared.clearToken()
    }
}
