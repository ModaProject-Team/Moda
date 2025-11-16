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

    func toDomain() -> EmailValidation {
        EmailValidation(message: message)
    }
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

    func toDomain() -> User {
        User(
            userId: userId,
            email: email,
            nickname: nickname,
            profileImage: nil,
            accessToken: nil,
            refreshToken: nil
        )
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

    func toDomain() -> User {
        User(
            userId: userId,
            email: email,
            nickname: nick,
            profileImage: profileImage,
            accessToken: accessToken,
            refreshToken: refreshToken
        )
    }
}

// MARK: - 회원 탈퇴
struct WithdrawResponse: Decodable {
    let userId: String
    let email: String
    let nick: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case nick
    }

    func toDomain() -> User {
        User(
            userId: userId,
            email: email,
            nickname: nick,
            profileImage: nil,
            accessToken: nil,
            refreshToken: nil
        )
    }
}

// MARK: - 유저 검색
struct UserSearchResponse: Decodable {
    let data: [SearchedUser]

    func toDomain() -> UserSearchResult {
        UserSearchResult(users: data.map { $0.toDomain() })
    }
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

    func toDomain() -> SearchedUserModel {
        SearchedUserModel(
            userId: userId,
            nickname: nick,
            profileImage: profileImage
        )
    }
}
