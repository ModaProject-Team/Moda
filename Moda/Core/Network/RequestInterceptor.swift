//
//  RequestInterceptor.swift
//  Moda
//
//  Created by 금가경 on 11/15/24.
//

import Foundation

/// 네트워크 요청/응답을 가로채서 처리하는 프로토콜
///
/// `RequestInterceptor`는 네트워크 요청 전후에 커스텀 로직을 실행할 수 있게 합니다.
/// 주로 인증 토큰 추가, 에러 재시도 등에 사용됩니다.
///
/// ## Overview
///
/// Interceptor는 두 가지 시점에 동작합니다:
/// - `adapt`: 요청을 보내기 **전**에 URLRequest를 수정
/// - `retry`: 응답 실패 **후**에 재시도 여부를 결정
///
/// ## Usage
///
/// ```swift
/// class TokenInterceptor: RequestInterceptor {
///     func adapt(_ request: URLRequest) async throws -> URLRequest {
///         var request = request
///         request.setValue(token, forHTTPHeaderField: "Authorization")
///         return request
///     }
///
///     func retry(_ request: URLRequest, dueTo error: Error) async throws -> Bool {
///         if isTokenExpired(error) {
///             try await refreshToken()
///             return true  // 재시도
///         }
///         return false  // 재시도 안함
///     }
/// }
/// ```
protocol RequestInterceptor {

    /// 요청을 보내기 전에 URLRequest를 수정합니다
    ///
    /// 이 메서드는 네트워크 요청이 실행되기 전에 호출되며,
    /// 헤더 추가, 파라미터 수정 등의 작업을 수행할 수 있습니다.
    ///
    /// - Parameter request: 원본 URLRequest
    /// - Returns: 수정된 URLRequest
    /// - Throws: 요청 수정 중 에러 발생 시
    ///
    /// ## Example
    ///
    /// ```swift
    /// func adapt(_ request: URLRequest) async throws -> URLRequest {
    ///     var request = request
    ///     request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    ///     return request
    /// }
    /// ```
    func adapt(_ request: URLRequest) async throws -> URLRequest

    /// 요청 실패 시 재시도 여부를 결정합니다
    ///
    /// 이 메서드는 네트워크 요청이 실패했을 때 호출되며,
    /// 재시도가 필요한지 여부를 판단합니다.
    ///
    /// - Parameters:
    ///   - request: 실패한 URLRequest
    ///   - error: 발생한 에러
    /// - Returns: 재시도 여부 (true: 재시도, false: 재시도 안함)
    /// - Throws: 재시도 준비 중 에러 발생 시 (예: 토큰 갱신 실패)
    ///
    /// ## Example
    ///
    /// ```swift
    /// func retry(_ request: URLRequest, dueTo error: Error) async throws -> Bool {
    ///     guard let networkError = error as? NetworkError else {
    ///         return false
    ///     }
    ///
    ///     if case .tokenExpired = networkError {
    ///         try await refreshToken()
    ///         return true
    ///     }
    ///
    ///     return false
    /// }
    /// ```
    func retry(_ request: URLRequest, dueTo error: Error) async throws -> Bool
}

/// RequestInterceptor 기본 구현
extension RequestInterceptor {
    /// 기본적으로 요청을 수정하지 않고 그대로 반환
    func adapt(_ request: URLRequest) async throws -> URLRequest {
        return request
    }

    /// 기본적으로 재시도하지 않음
    func retry(_ request: URLRequest, dueTo error: Error) async throws -> Bool {
        return false
    }
}
