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

    private let keychain = KeychainManager.shared

    private enum Keys {
        static let accessToken = "moda_access_token"
        static let refreshToken = "moda_refresh_token"
    }

    var accessToken: String? {
        get {
            return keychain.load(key: Keys.accessToken)
        }
        set {
            if let value = newValue {
                _ = keychain.save(key: Keys.accessToken, value: value)
            } else {
                _ = keychain.delete(key: Keys.accessToken)
            }
        }
    }

    var refreshToken: String? {
        get {
            return keychain.load(key: Keys.refreshToken)
        }
        set {
            if let value = newValue {
                _ = keychain.save(key: Keys.refreshToken, value: value)
            } else {
                _ = keychain.delete(key: Keys.refreshToken)
            }
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
