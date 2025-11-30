//
//  UserRealmService.swift
//  Moda
//
//  Created by 금가경 on 11/30/25.
//

import Foundation
import RealmSwift

/// 사용자 프로필 로컬 저장소 구현체
actor UserRealmService: UserRealmServiceProtocol {
    static let shared = UserRealmService()

    private let configuration: Realm.Configuration

    private init() {
        self.configuration = RealmMigration.configuration()
    }

    private func getRealm() throws -> Realm {
        return try Realm(configuration: configuration)
    }

    func saveMyProfile(_ user: UserObject) async throws {
        let realm = try getRealm()
        try realm.write {
            realm.add(user, update: .modified)
        }
    }

    func getMyProfileData() async -> UserProfileData? {
        guard let realm = try? getRealm() else {
            return nil
        }

        guard let realmObject = realm.objects(UserObject.self).first else {
            return nil
        }

        // actor 내에서 즉시 일반 struct로 변환
        return UserProfileData(from: realmObject)
    }

    func deleteMyProfile() async throws {
        let realm = try getRealm()
        let allUsers = realm.objects(UserObject.self)

        try realm.write {
            realm.delete(allUsers)
        }
    }
}
