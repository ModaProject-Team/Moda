//
//  FriendObject.swift
//  Moda
//
//  Created by 금가경 on 11/30/25.
//

import Foundation
import RealmSwift

/// 친구 정보 로컬 저장 모델
class FriendObject: Object {
    @Persisted(primaryKey: true) var userId: String
    @Persisted var nick: String
    @Persisted var info1: String?
    @Persisted var profileImage: String?
    @Persisted var updatedAt: Date

    convenience init(
        userId: String,
        nick: String,
        info1: String?,
        profileImage: String?,
        updatedAt: Date = Date()
    ) {
        self.init()
        self.userId = userId
        self.nick = nick
        self.info1 = info1
        self.profileImage = profileImage
        self.updatedAt = updatedAt
    }
}

extension FriendObject {
    /// OtherProfileResponse로부터 FriendObject 생성
    /// - Parameter response: 서버 응답 DTO
    /// - Returns: FriendObject 인스턴스
    static func from(response: OtherProfileResponse) -> FriendObject {
        return FriendObject(
            userId: response.userId,
            nick: response.nick,
            info1: response.info1,
            profileImage: response.profileImage
        )
    }
}
