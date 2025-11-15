//
//  AuthServiceProtocol.swift
//  Moda
//
//  Created by 금가경 on 11/14/24.
//

import Foundation

/// 인증 토큰 관련 서비스 프로토콜
protocol AuthServiceProtocol {
    func refreshToken() async throws -> RefreshTokenResponse
}
