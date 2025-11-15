//
//  AuthDTO.swift
//  Moda
//
//  Created by 금가경 on 11/14/24.
//

import Foundation

// MARK: - 토큰 갱신
struct RefreshTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
}
