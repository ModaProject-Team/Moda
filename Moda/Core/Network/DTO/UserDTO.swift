//
//  UserDTO.swift
//  Moda
//
//  Created by 금가경 on 11/12/24.
//

import Foundation

// MARK: - 이메일 중복 체크
struct EmailValidationResponse: Decodable {
    let message: String
}

// MARK: - 회원가입
struct SignUpResponse: Decodable {
    let userId: String
    let email: String
    let nickname: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case nickname = "nick"
    }
}

// MARK: - 로그인
struct LoginResponse: Decodable {
    let userId: String
    let email: String
    let nick: String
    let profileImage: String?
    let accessToken: String
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case nick
        case profileImage
        case accessToken
        case refreshToken
    }
}

struct WithdrawResponse: Decodable {
    let userId: String
    let email: String
    let nick: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case nick
    }
}

// MARK: - 유저 검색
struct UserSearchResponse: Decodable {
    let data: [SearchedUser]
}

struct SearchedUser: Decodable, Identifiable {
    let userId: String
    let nick: String
    let profileImage: String?
    var id: String { userId }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nick
        case profileImage
    }
}
