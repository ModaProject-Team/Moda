//
//  UserServiceProtocol.swift
//  Moda
//
//  Created by 금가경 on 11/12/24.
//

import Foundation

/// 사용자 관련 서비스 프로토콜
protocol UserServiceProtocol {
    func signUp(email: String, password: String, nickname: String) async throws -> SignUpResponse
    func login(email: String, password: String) async throws -> LoginResponse
    func loginWithKakao(idToken: String) async throws -> LoginResponse
    func loginWithApple(idToken: String) async throws -> LoginResponse
    func logout()
}
