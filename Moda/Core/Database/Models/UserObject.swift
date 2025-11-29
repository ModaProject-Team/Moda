//
//  UserObject.swift
//  Moda
//
//  Created by 금가경 on 11/30/25.
//

import Foundation
import RealmSwift

/// 내 프로필 정보 로컬 저장 모델
class UserObject: Object {
    @Persisted(primaryKey: true) var userId: String
    @Persisted var email: String?
    @Persisted var nick: String
    @Persisted var profileImage: String?
    @Persisted var phoneNum: String?
    @Persisted var gender: String?
    @Persisted var birthDay: String?
    @Persisted var info1: String?
    @Persisted var info2: String?
    @Persisted var info3: String?
    @Persisted var info4: String?
    @Persisted var info5: String?
    @Persisted var updatedAt: Date

    convenience init(
        userId: String,
        email: String?,
        nick: String,
        profileImage: String?,
        phoneNum: String?,
        gender: String?,
        birthDay: String?,
        info1: String?,
        info2: String?,
        info3: String?,
        info4: String?,
        info5: String?,
        updatedAt: Date = Date()
    ) {
        self.init()
        self.userId = userId
        self.email = email
        self.nick = nick
        self.profileImage = profileImage
        self.phoneNum = phoneNum
        self.gender = gender
        self.birthDay = birthDay
        self.info1 = info1
        self.info2 = info2
        self.info3 = info3
        self.info4 = info4
        self.info5 = info5
        self.updatedAt = updatedAt
    }
}

extension UserObject {
    /// MyProfileResponse로부터 UserObject 생성
    /// - Parameter response: 서버 응답 DTO
    /// - Returns: UserObject 인스턴스
    static func from(response: MyProfileResponse) -> UserObject {
        return UserObject(
            userId: response.userId,
            email: response.email,
            nick: response.nick,
            profileImage: response.profileImage,
            phoneNum: response.phoneNum,
            gender: response.gender,
            birthDay: response.birthDay,
            info1: response.info1,
            info2: response.info2,
            info3: response.info3,
            info4: response.info4,
            info5: response.info5
        )
    }

    /// UserObject를 MyProfileResponse로 변환
    /// - Returns: MyProfileResponse 인스턴스
    func toMyProfileResponse() -> MyProfileResponse {
        return MyProfileResponse(
            userId: userId,
            email: email ?? "",
            nick: nick,
            profileImage: profileImage,
            phoneNum: phoneNum,
            gender: gender,
            birthDay: birthDay,
            info1: info1,
            info2: info2,
            info3: info3,
            info4: info4,
            info5: info5,
            followers: [],
            following: [],
            posts: []
        )
    }
}
