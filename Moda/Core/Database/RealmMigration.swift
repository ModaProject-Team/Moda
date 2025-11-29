//
//  RealmMigration.swift
//  Moda
//
//  Created by 금가경 on 11/29/25.
//

import Foundation
import RealmSwift

/// Realm 스키마 마이그레이션 관리
final class RealmMigration {
    /// 현재 Realm 스키마 버전
    static let currentSchemaVersion: UInt64 = 1

    /// Realm Configuration 생성
    /// - Returns: 마이그레이션이 설정된 Realm Configuration
    static func configuration() -> Realm.Configuration {
        var config = Realm.Configuration.defaultConfiguration
        config.schemaVersion = currentSchemaVersion
        config.migrationBlock = { migration, oldSchemaVersion in
            if oldSchemaVersion < 1 {
                // 초기 버전 (0 → 1)
                // 새로운 프로퍼티 추가 시 자동 마이그레이션
            }

            // 향후 버전 마이그레이션 예시:
            // if oldSchemaVersion < 2 {
            //     migration.enumerateObjects(ofType: ChatMessageObject.className()) { oldObject, newObject in
            //         // 필드 변경 또는 데이터 변환
            //     }
            // }
        }

        return config
    }

    /// Realm 초기화 및 마이그레이션 실행
    /// - Throws: Realm 초기화 실패 시 에러
    static func setup() throws {
        let config = configuration()
        _ = try Realm(configuration: config)
        print("✅ Realm Migration completed (schema version: \(currentSchemaVersion))")
    }
}
