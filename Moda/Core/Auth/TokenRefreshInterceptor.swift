//
//  TokenRefreshInterceptor.swift
//  Moda
//
//  Created by 금가경 on 11/15/24.
//

import Foundation

/// 토큰 만료 시 자동으로 갱신하고 재시도하는 Interceptor
///
/// `TokenRefreshInterceptor`는 AccessToken 만료(419 에러) 발생 시
/// 자동으로 RefreshToken을 사용하여 토큰을 갱신하고 실패한 요청을 재시도합니다.
///
/// ## 동작 방식
///
/// 1. API 요청 실패 시 에러 확인
/// 2. 419 에러(AccessToken 만료)인 경우 토큰 갱신
/// 3. 갱신 성공 시 원래 요청 재시도
/// 4. 갱신 실패 시 에러 throw
///
/// ## Race Condition 방지
///
/// 여러 요청이 동시에 419 에러를 받아도 토큰은 한 번만 갱신됩니다:
/// - 첫 번째 요청만 실제로 토큰 갱신 API 호출
/// - 나머지 요청들은 대기 후 갱신된 토큰 사용
final class TokenRefreshInterceptor: RequestInterceptor {

    /// 토큰 갱신 중인지 여부
    private var isRefreshing = false

    /// 토큰 갱신 대기 중인 작업들
    private var refreshTasks: [CheckedContinuation<Void, Error>] = []

    /// 토큰 갱신 시 자동으로 재시도합니다
    ///
    /// - Parameters:
    ///   - request: 실패한 URLRequest
    ///   - error: 발생한 에러
    /// - Returns: 재시도 여부 (419 에러일 경우 true)
    /// - Throws: 토큰 갱신 실패 시 NetworkError
    func retry(_ request: URLRequest, dueTo error: Error) async throws -> Bool {
        // NetworkError가 아니면 재시도 안함
        guard let networkError = error as? NetworkError else {
            return false
        }

        // 419 에러(AccessToken 만료)가 아니면 재시도 안함
        guard case .tokenExpired = networkError else {
            return false
        }

        // 토큰 갱신 후 재시도
        try await refreshTokenIfNeeded()
        return true
    }

    /// 토큰 갱신이 필요한 경우 RefreshToken을 사용하여 새로운 토큰을 발급받습니다
    ///
    /// ## 동시 요청 처리 (Race Condition 방지)
    ///
    /// 여러 API 요청이 동시에 419 에러를 받았을 때:
    /// 1. 첫 번째 요청만 실제로 refreshToken API를 호출하여 토큰 갱신
    /// 2. 나머지 요청들은 Continuation을 사용하여 대기
    /// 3. 토큰 갱신 완료 후 대기 중인 모든 요청을 resume()으로 깨움
    /// 4. 깨어난 요청들은 갱신된 토큰을 사용하여 재시도
    ///
    /// - Throws: 토큰 갱신 실패 시 NetworkError
    private func refreshTokenIfNeeded() async throws {
        // 이미 토큰 갱신 중이면 대기
        if isRefreshing {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                refreshTasks.append(continuation)
            }
            return
        }

        // refreshToken이 없으면 에러
        guard TokenManager.shared.refreshToken != nil else {
            throw NetworkError.serverError(message: "로그인이 필요합니다")
        }

        isRefreshing = true

        do {
            // refreshToken API 호출
            let refreshResponse = try await AuthService.shared.refreshToken()

            // 새 토큰 저장 (AuthService에서 이미 저장하지만 명시적으로 확인)
            TokenManager.shared.saveToken(
                accessToken: refreshResponse.accessToken,
                refreshToken: refreshResponse.refreshToken
            )

            // 대기 중인 모든 작업 재개
            refreshTasks.forEach { $0.resume() }
            refreshTasks.removeAll()

            isRefreshing = false
        } catch {
            // 에러 발생 시 대기 중인 모든 작업에게 에러 전달
            refreshTasks.forEach { $0.resume(throwing: error) }
            refreshTasks.removeAll()

            isRefreshing = false

            throw error
        }
    }
}
