//
//  User.swift
//  Moda
//
//  Created by 금가경 on 11/15/24.
//

import Foundation

/// 앱 내부에서 사용하는 사용자 Domain Model
struct User {
    let userId: String
    let email: String
    let nickname: String
    let profileImage: String?
    let accessToken: String?
    let refreshToken: String?
}

/// 이메일 중복 체크 결과
struct EmailValidation {
    let message: String
}

/// 검색된 사용자
struct SearchedUserModel {
    let userId: String
    let nickname: String
    let profileImage: String?
}

/// 유저 검색 결과
struct UserSearchResult {
    let users: [SearchedUserModel]
}
