//
//  AuthAPIProtocol.swift
//  Moda
//
//  Created by 금가경 on 11/14/24.
//

import Foundation

/// 인증 토큰 관련 API 프로토콜
protocol AuthAPIProtocol {
    func refreshToken() async throws -> RefreshTokenResponse
}
