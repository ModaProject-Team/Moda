//
//  FriendRealmService.swift
//  Moda
//
//  Created by 금가경 on 11/30/25.
//

import Foundation
import RealmSwift

/// 친구 목록 로컬 저장소 구현체
actor FriendRealmService: FriendRealmServiceProtocol {
    static let shared = FriendRealmService()

    private let configuration: Realm.Configuration

    private init() {
        self.configuration = RealmMigration.configuration()
    }

    private func getRealm() throws -> Realm {
        return try Realm(configuration: configuration)
    }

    func saveFriends(_ friends: [FriendObject]) async throws {
        let realm = try getRealm()
        try realm.write {
            for friend in friends {
                realm.add(friend, update: .modified)
            }
        }
    }

    func getAllFriendsData() async -> [FriendData] {
        guard let realm = try? getRealm() else { return [] }

        let results = realm.objects(FriendObject.self)
            .sorted(byKeyPath: "nick", ascending: true)

        // actor 내에서 즉시 일반 struct로 변환
        return Array(results.map { FriendData(from: $0) })
    }

    func deleteAllFriends() async throws {
        let realm = try getRealm()
        let allFriends = realm.objects(FriendObject.self)

        try realm.write {
            realm.delete(allFriends)
        }
    }
}
