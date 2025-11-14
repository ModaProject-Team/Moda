//
//  AuthService.swift
//  Moda
//
//  Created by 금가경 on 11/12/24.
//

import Foundation

final class AuthService: AuthServiceProtocol {
    static let shared = AuthService()

    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
    }

    func signUp(email: String, password: String, nickname: String) async throws -> SignUpResponse {
        let endpoint = APIRouter.signUp(
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
        let endpoint = APIRouter.login(email: email, password: password)
        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: LoginResponse.self
        )

        TokenManager.shared.saveToken(accessToken: response.accessToken)

        return response
    }

    func loginWithKakao(idToken: String) async throws -> LoginResponse {
        let endpoint = APIRouter.loginKakao(token: idToken)
        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: LoginResponse.self
        )

        TokenManager.shared.saveToken(accessToken: response.accessToken)

        return response
    }

    func loginWithApple(idToken: String) async throws -> LoginResponse {
        let endpoint = APIRouter.loginApple(token: idToken)
        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: LoginResponse.self
        )

        TokenManager.shared.saveToken(accessToken: response.accessToken)

        return response
    }

    func logout() {
        TokenManager.shared.clearToken()
    }
}
