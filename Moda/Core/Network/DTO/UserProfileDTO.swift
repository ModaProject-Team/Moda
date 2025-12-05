//
//  UserProfileDTO.swift
//  Moda
//
//  Created by 금가경 on 11/15/24.
//

import Foundation

// MARK: - 내 프로필 조회 응답
struct MyProfileResponse: Decodable {
    let userId: String
    let email: String
    let nick: String
    let profileImage: String?
    let phoneNum: String?
    let gender: String?
    let birthDay: String?
    let info1: String?
    let info2: String?
    let info3: String?
    let info4: String?
    let info5: String?
    let followers: [ProfileUser]
    let following: [ProfileUser]
    let posts: [String]

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case nick
        case profileImage
        case phoneNum
        case gender
        case birthDay
        case info1
        case info2
        case info3
        case info4
        case info5
        case followers
        case following
        case posts
    }

    func toDomain() -> UserProfile {
        UserProfile(
            userId: userId,
            email: email,
            nickname: nick,
            profileImage: profileImage,
            phoneNum: phoneNum,
            gender: gender,
            birthDay: birthDay,
            info1: info1,
            info2: info2,
            info3: info3,
            info4: info4,
            info5: info5,
            followers: followers.map { $0.toDomain() },
            following: following.map { $0.toDomain() },
            posts: posts
        )
    }
}

// MARK: - 다른 사람 프로필 조회 응답
struct OtherProfileResponse: Decodable {
    let userId: String
    let nick: String
    let profileImage: String?
    let info1: String?
    let info2: String?
    let info3: String?
    let info4: String?
    let info5: String?
    let followers: [ProfileUser]
    let following: [ProfileUser]
    let posts: [String]

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nick
        case profileImage
        case info1
        case info2
        case info3
        case info4
        case info5
        case followers
        case following
        case posts
    }

    func toDomain() -> UserProfile {
        UserProfile(
            userId: userId,
            email: nil,
            nickname: nick,
            profileImage: profileImage,
            phoneNum: nil,
            gender: nil,
            birthDay: nil,
            info1: info1,
            info2: info2,
            info3: info3,
            info4: info4,
            info5: info5,
            followers: followers.map { $0.toDomain() },
            following: following.map { $0.toDomain() },
            posts: posts
        )
    }
}

// MARK: - 프로필 내 팔로워/팔로잉 사용자 정보
struct ProfileUser: Decodable {
    let userId: String
    let nick: String
    let profileImage: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nick
        case profileImage
    }

    func toDomain() -> ProfileUserModel {
        ProfileUserModel(
            userId: userId,
            nickname: nick,
            profileImage: profileImage
        )
    }
}

// MARK: - Chat Helper Types

struct ChatUserData {
    let userId: String
    let profile: MyProfileResponse
}
