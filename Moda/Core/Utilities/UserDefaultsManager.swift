//
//  UserDefaultsManager.swift
//  Moda
//
//  Created by 금가경 on 11/28/25.
//

import Foundation

/// UserDefaults 키와 값을 타입 안전하게 관리하는 매니저
final class UserDefaultsManager {
    private init() {}

    static let shared = UserDefaultsManager()

    private let defaults = UserDefaults.standard

    /// UserDefaults 키 정의
    enum Key: String {
        case userId = "userId"
    }

    /// 현재 로그인한 사용자 ID
    var userId: String? {
        get {
            defaults.string(forKey: Key.userId.rawValue)
        }
        set {
            if let value = newValue {
                defaults.set(value, forKey: Key.userId.rawValue)
            } else {
                defaults.removeObject(forKey: Key.userId.rawValue)
            }
        }
    }

    /// 모든 사용자 데이터 삭제
    func clearUserData() {
        defaults.removeObject(forKey: Key.userId.rawValue)
    }
}
