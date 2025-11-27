//
//  UserAPIProtocol.swift
//  Moda
//
//  Created by 금가경 on 11/12/24.
//

import Foundation

/// 사용자 관련 API 프로토콜
protocol UserAPIProtocol {
    func validateEmail(email: String) async throws -> EmailValidationResponse
    func signUp(email: String, password: String, nickname: String) async throws -> SignUpResponse
    func login(email: String, password: String) async throws -> LoginResponse
    func loginWithKakao(oauthToken: String) async throws -> LoginResponse
    func loginWithApple(idToken: String) async throws -> LoginResponse
    func withdraw() async throws -> WithdrawResponse
    func searchUsers(query: String) async throws -> UserSearchResponse
}
