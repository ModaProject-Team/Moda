//
//  TokenManager.swift
//  Moda
//
//  Created by 금가경 on 11/12/24.
//

import Foundation

final class TokenManager {
    private init() {}

    static let shared = TokenManager()

    private let userDefaults = UserDefaults.standard

    private enum Keys {
        static let accessToken = "moda_access_token"
        static let refreshToken = "moda_refresh_token"
    }

    var accessToken: String? {
        get {
            return userDefaults.string(forKey: Keys.accessToken)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.accessToken)
        }
    }

    var refreshToken: String? {
        get {
            return userDefaults.string(forKey: Keys.refreshToken)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.refreshToken)
        }
    }

    var isLoggedIn: Bool {
        return accessToken != nil
    }
    
    func saveToken(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
    
    func clearToken() {
        accessToken = nil
        refreshToken = nil
    }
}
