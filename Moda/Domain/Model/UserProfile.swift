//
//  UserProfile.swift
//  Moda
//
//  Created by 금가경 on 11/15/24.
//

import Foundation

/// 사용자 프로필 Domain Model
struct UserProfile {
    let userId: String
    let email: String?
    let nickname: String
    let profileImage: String?
    let phoneNum: String?
    let gender: String?
    let birthDay: String?
    let info1: String?
    let info2: String?
    let info3: String?
    let info4: String?
    let info5: String?
    let followers: [ProfileUserModel]
    let following: [ProfileUserModel]
    let posts: [String]
}

/// 프로필 내 팔로워/팔로잉 사용자
struct ProfileUserModel {
    let userId: String
    let nickname: String
    let profileImage: String?
}
