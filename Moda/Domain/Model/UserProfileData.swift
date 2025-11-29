//
//  UserProfileData.swift
//  Moda
//
//  Created by 금가경 on 11/30/25.
//

import Foundation

/// 내 프로필 정보를 담는 일반 struct (Realm 객체가 아님)
struct UserProfileData {
    let userId: String
    let email: String?
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

    init(from realmObject: UserObject) {
        self.userId = realmObject.userId
        self.email = realmObject.email
        self.nick = realmObject.nick
        self.profileImage = realmObject.profileImage
        self.phoneNum = realmObject.phoneNum
        self.gender = realmObject.gender
        self.birthDay = realmObject.birthDay
        self.info1 = realmObject.info1
        self.info2 = realmObject.info2
        self.info3 = realmObject.info3
        self.info4 = realmObject.info4
        self.info5 = realmObject.info5
    }

    init(from response: MyProfileResponse) {
        self.userId = response.userId
        self.email = response.email
        self.nick = response.nick
        self.profileImage = response.profileImage
        self.phoneNum = response.phoneNum
        self.gender = response.gender
        self.birthDay = response.birthDay
        self.info1 = response.info1
        self.info2 = response.info2
        self.info3 = response.info3
        self.info4 = response.info4
        self.info5 = response.info5
    }
}
