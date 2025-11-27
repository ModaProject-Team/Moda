//
//  UserRouter.swift
//  Moda
//
//  Created by 금가경 on 11/14/24.
//

import Foundation

/// 사용자 관련 API 엔드포인트
enum UserRouter {

    /// 이메일 중복 확인
    case validateEmail(email: String)

    /// 회원가입
    case signUp(email: String, password: String, nickname: String)

    /// 이메일 로그인
    case login(email: String, password: String)

    /// 카카오 로그인
    case loginKakao(oauthToken: String)

    /// 애플 로그인
    case loginApple(token: String)

    /// 회원 탈퇴
    case withdraw

    /// 유저 검색
    case searchUsers(query: String)
}

// MARK: - Endpoint 구현
extension UserRouter: Endpoint {

    var baseURL: String {
        return NetworkConfig.baseURL
    }

    var path: String {
        let basePath = "/v1/users"
        let subPath: String

        switch self {
        case .validateEmail:
            subPath = "/validation/email"
        case .signUp:
            subPath = "/join"
        case .login:
            subPath = "/login"
        case .loginKakao:
            subPath = "/login/kakao"
        case .loginApple:
            subPath = "/login/apple"
        case .withdraw:
            subPath = "/withdraw"
        case .searchUsers:
            subPath = "/search"
        }

        return basePath + subPath
    }

    var method: HTTPMethod {
        switch self {
        case .validateEmail, .signUp, .login, .loginKakao, .loginApple:
            return .post
        case .withdraw, .searchUsers:
            return .get
        }
    }

    var headers: [String: String]? {
        var headers = ["Content-Type": "application/json"]

        headers["SesacKey"] = NetworkConfig.sesacKey
        headers["ProductId"] = NetworkConfig.productId

        // 로그인 API는 토큰 불필요, 나머지는 Authorization 헤더 필요
        if let accessToken = TokenManager.shared.accessToken {
            headers["Authorization"] = accessToken
        }

        return headers
    }

    var parameters: [String: Any]? {
        switch self {
        case .validateEmail(let email):
            return ["email": email]
        case .signUp(let email, let password, let nickname):
            return [
                "email": email,
                "password": password,
                "nick": nickname
            ]
        case .login(let email, let password):
            return [
                "email": email,
                "password": password
            ]
        case .loginKakao(let token), .loginApple(let token):
            return ["oauthToken": token]
        default:
            return nil
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .searchUsers(let query):
            return [URLQueryItem(name: "nick", value: query)]
        default:
            return nil
        }
    }
}
