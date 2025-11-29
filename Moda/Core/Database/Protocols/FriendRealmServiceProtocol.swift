//
//  FriendRealmServiceProtocol.swift
//  Moda
//
//  Created by 금가경 on 11/30/25.
//

import Foundation

/// 친구 목록 로컬 저장소 프로토콜
protocol FriendRealmServiceProtocol: Actor {
    /// 친구 여러 명 저장/업데이트
    /// - Parameter friends: 친구 객체 배열
    func saveFriends(_ friends: [FriendObject]) async throws

    /// 모든 친구 조회 (일반 struct로 반환)
    /// - Returns: 친구 데이터 배열 (이름순)
    func getAllFriendsData() async -> [FriendData]

    /// 모든 친구 삭제
    func deleteAllFriends() async throws
}
