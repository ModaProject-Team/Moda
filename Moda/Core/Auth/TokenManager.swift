//
//  TokenManager.swift
//  Moda
//
//  Created by 금가경 on 11/12/24.
//

import Foundation

final class TokenManager {
    static let shared = TokenManager()

    private let userDefaults = UserDefaults.standard

    private enum Keys {
        static let accessToken = "moda_access_token"
    }

    var accessToken: String? {
        get {
            return userDefaults.string(forKey: Keys.accessToken)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.accessToken)
        }
    }

    var isLoggedIn: Bool {
        return accessToken != nil
    }

    private init() {}

    func saveToken(accessToken: String) {
        self.accessToken = accessToken
    }

    func clearToken() {
        accessToken = nil
    }
}
