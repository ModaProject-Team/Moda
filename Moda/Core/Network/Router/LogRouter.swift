//
//  LogRouter.swift
//  Moda
//
//  Created by 금가경 on 11/14/24.
//

import Foundation

/// 로그 관련 API 엔드포인트
enum LogRouter {

    /// 서버 로그 조회 (디버깅용)
    ///
    /// 서버에 기록된 API 호출 로그를 조회합니다.
    /// 개발 및 디버깅 목적으로만 사용되며, 프로덕션에서는 사용하지 않습니다.
    ///
    /// - Returns: ``LogResponse`` - 로그 목록과 개수
    ///
    /// ## HTTP 요청 상세
    /// - Method: GET
    /// - Path: `/v1/logs`
    /// - Auth: 불필요
    ///
    /// ## 응답 규칙
    /// - 최신순으로 정렬되어 최대 100개의 로그를 반환합니다
    /// - 로그가 없는 경우 빈 배열을 반환합니다
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let response = try await NetworkService.shared.request(
    ///     endpoint: LogRouter.getLogs,
    ///     responseType: LogResponse.self
    /// )
    ///
    /// print("총 로그 개수: \(response.count)")
    /// for log in response.logs {
    ///     print("\(log.date) - \(log.method) \(log.routePath)")
    /// }
    /// ```
    ///
    /// - Note: 서버 성능에 영향을 줄 수 있으므로 자주 호출하지 않도록 주의하세요.
    case getLogs
}

// MARK: - Endpoint 구현
extension LogRouter: Endpoint {

    var baseURL: String {
        return NetworkConfig.baseURL
    }

    var path: String {
        let basePath = "/v1/logs"

        switch self {
        case .getLogs:
            return basePath
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getLogs:
            return .get
        }
    }

    var headers: [String: String]? {
        var headers = ["Content-Type": "application/json"]

        headers["SesacKey"] = NetworkConfig.sesacKey
        headers["ProductId"] = NetworkConfig.productId

        if let accessToken = TokenManager.shared.accessToken {
            headers["Authorization"] = accessToken
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
