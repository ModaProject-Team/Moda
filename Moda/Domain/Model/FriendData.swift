//
//  FriendData.swift
//  Moda
//
//  Created by 금가경 on 11/30/25.
//

import Foundation

/// 친구 정보를 담는 일반 struct (Realm 객체가 아님)
struct FriendData {
    let userId: String
    let nick: String
    let info1: String?
    let profileImage: String?

    init(from realmObject: FriendObject) {
        self.userId = realmObject.userId
        self.nick = realmObject.nick
        self.info1 = realmObject.info1
        self.profileImage = realmObject.profileImage
    }

    init(from response: OtherProfileResponse) {
        self.userId = response.userId
        self.nick = response.nick
        self.info1 = response.info1
        self.profileImage = response.profileImage
    }
}
