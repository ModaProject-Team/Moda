//
//  AuthRouter.swift
//  Moda
//
//  Created by 금가경 on 11/14/24.
//

import Foundation

/// 인증 관련 API 엔드포인트
enum AuthRouter {

    /// 토큰 갱신
    ///
    /// refreshToken과 만료된 accessToken을 사용하여 새로운 accessToken과 refreshToken을 발급받습니다.
    ///
    /// - Returns: ``RefreshTokenResponse`` - 새로운 액세스 토큰 및 리프레시 토큰
    ///
    /// ## HTTP 요청 상세
    /// - Method: GET
    /// - Path: `/v1/auth/refresh`
    /// - Header:
    ///   - Authorization: 만료된 액세스 토큰
    ///   - RefreshToken: 리프레시 토큰
    /// - Base URL: ``NetworkConfig.baseURL``
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let response = try await NetworkService.shared.request(
    ///     endpoint: AuthRouter.refreshToken,
    ///     responseType: RefreshTokenResponse.self
    /// )
    ///
    /// // 새 토큰 저장
    /// TokenManager.shared.saveToken(
    ///     accessToken: response.accessToken,
    ///     refreshToken: response.refreshToken
    /// )
    /// ```
    ///
    /// ## 주의사항
    /// - accessToken 만료 시(419 에러) 자동으로 호출됩니다
    /// - refreshToken도 함께 갱신되므로 반드시 저장해야 합니다
    /// - 서버 요구사항: 만료된 accessToken과 refreshToken을 모두 전송해야 합니다
    ///
    /// - Note: ``NetworkService``에서 419 에러 발생 시 자동으로 호출됩니다.
    case refreshToken
}

// MARK: - Endpoint 구현
extension AuthRouter: Endpoint {

    var baseURL: String {
        return NetworkConfig.baseURL
    }

    var path: String {
        switch self {
        case .refreshToken:
            return "/v1/auth/refresh"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .refreshToken:
            return .get
        }
    }

    var headers: [String: String]? {

        var headers: [String: String] = [
            "Content-Type": "application/json",
            "SesacKey": NetworkConfig.sesacKey,
            "ProductId": NetworkConfig.productId
        ]

        switch self {
        case .refreshToken:
            // 만료된 AccessToken도 함께 전송 (서버에서 요구)
            if let accessToken = TokenManager.shared.accessToken {
                headers["Authorization"] = accessToken
            }
            // RefreshToken 추가
            if let refreshToken = TokenManager.shared.refreshToken {
                headers["RefreshToken"] = refreshToken
            }
        }
        return headers
    }

    var parameters: [String: Any]? {
        return nil
    }

    var queryItems: [URLQueryItem]? {
        return nil
    }
}
