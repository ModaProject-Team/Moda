//
//  NetworkService.swift
//  Moda
//
//  Created by 금가경 on 11/12/24.
//

import Foundation

/// URLSession 기반의 네트워크 통신을 담당하는 서비스
///
/// `NetworkService`는 RESTful API 요청을 수행하고 응답을 처리하는 네트워크 레이어입니다.
/// 싱글톤 패턴을 사용하며, 프로토콜 기반 DI를 통해 테스트 가능합니다.
///
/// ## Overview
///
/// 이 서비스는 다음과 같은 기능을 제공합니다:
/// - HTTP 요청 수행 및 응답 처리
/// - 자동 JSON 인코딩/디코딩
/// - 네트워크 연결 상태 확인
/// - 표준화된 에러 처리
/// - accessToken 자동 갱신 (419 에러 시)
/// - 타임아웃 설정 (요청: 30초, 리소스: 60초)
///
/// ## Usage
///
/// ### 기본 사용법
///
/// ```swift
/// // 1. API 요청 수행
/// let response = try await NetworkService.shared.request(
///     endpoint: APIRouter.login(email: "test@example.com", password: "password"),
///     responseType: LoginResponse.self
/// )
///
/// // 2. 응답 데이터 사용
/// print("User ID: \(response.userId)")
/// print("Access Token: \(response.accessToken)")
/// ```
///
/// ### 응답이 필요없는 요청
///
/// ```swift
/// // 응답 본문이 필요없는 경우
/// try await NetworkService.shared.requestWithoutResponse(
///     endpoint: APIRouter.withdraw
/// )
/// ```
///
/// ### 에러 처리
///
/// ```swift
/// do {
///     let response = try await NetworkService.shared.request(
///         endpoint: APIRouter.signUp(email: email, password: password, nickname: nickname),
///         responseType: SignUpResponse.self
///     )
/// } catch let error as NetworkError {
///     switch error {
///     case .networkFailure:
///         print("네트워크 연결을 확인해주세요")
///     case .serverError(let message):
///         print("서버 에러: \(message)")
///     case .decodingError:
///         print("데이터 파싱 실패")
///     default:
///         print("알 수 없는 에러")
///     }
/// }
/// ```
///
/// ## Topics
///
/// ### 인스턴스 생성
/// - ``shared``
///
/// ### API 요청
/// - ``request(endpoint:responseType:)``
/// - ``requestWithoutResponse(endpoint:)``
///
/// ### 에러 처리
/// - ``NetworkError``
///
/// - Note: 모든 API 요청은 비동기로 수행되며 `async/await`를 사용합니다.
/// - Important: 네트워크 요청 전에 자동으로 연결 상태를 확인하므로, 별도의 네트워크 체크가 필요하지 않습니다.
final class NetworkService: NetworkServiceProtocol {
    /// 네트워크 서비스의 싱글톤 인스턴스
    ///
    /// 앱 전역에서 사용되는 단일 `NetworkService` 인스턴스입니다.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let response = try await NetworkService.shared.request(
    ///     endpoint: APIRouter.getMyProfile,
    ///     responseType: ProfileResponse.self
    /// )
    /// ```
    static let shared = NetworkService()

    /// URLSession 인스턴스
    ///
    /// 모든 네트워크 요청에 사용되는 세션입니다.
    /// 타임아웃 설정이 적용된 커스텀 configuration을 사용합니다.
    private let session: URLSession

    /// Request Interceptor 목록
    ///
    /// 요청/응답을 가로채서 처리하는 Interceptor들의 배열입니다.
    /// 순서대로 실행됩니다.
    private var interceptors: [RequestInterceptor] = []

    /// 네트워크 서비스를 초기화합니다
    ///
    /// 커스텀 URLSession configuration을 설정하여 초기화합니다.
    /// - 요청 타임아웃: 30초
    /// - 리소스 타임아웃: 60초
    ///
    /// - Note: 싱글톤 패턴을 사용하므로 외부에서 직접 초기화할 수 없습니다. `shared` 인스턴스를 사용하세요.
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)

        // 기본 Interceptor 추가
        self.interceptors = [TokenRefreshInterceptor()]
    }

    /// Interceptor를 추가합니다
    ///
    /// - Parameter interceptor: 추가할 RequestInterceptor
    func addInterceptor(_ interceptor: RequestInterceptor) {
        interceptors.append(interceptor)
    }

    /// API 요청을 수행하고 응답을 디코딩합니다
    ///
    /// 지정된 엔드포인트로 HTTP 요청을 보내고, 응답을 지정된 타입으로 디코딩하여 반환합니다.
    /// 네트워크 연결 상태를 자동으로 확인하며, HTTP 상태 코드에 따라 적절한 에러를 throw합니다.
    ///
    /// - Parameters:
    ///   - endpoint: 요청할 API 엔드포인트. `APIRouter` enum을 사용합니다.
    ///   - responseType: 응답 데이터의 타입. `Decodable` 프로토콜을 준수해야 합니다.
    ///
    /// - Returns: 디코딩된 응답 객체
    ///
    /// - Throws:
    ///   - `NetworkError.networkFailure`: 네트워크 연결이 없는 경우
    ///   - `NetworkError.invalidURL`: 잘못된 URL인 경우
    ///   - `NetworkError.invalidResponse`: 서버 응답이 유효하지 않은 경우
    ///   - `NetworkError.serverError(message:)`: 서버에서 에러를 반환한 경우 (400-499)
    ///   - `NetworkError.internalServerError`: 서버 내부 오류 (500-599)
    ///   - `NetworkError.decodingError`: JSON 디코딩 실패
    ///   - `NetworkError.unknown`: 알 수 없는 에러
    ///
    /// ## HTTP 상태 코드 처리
    ///
    /// - `200-299`: 성공, 응답 본문을 디코딩하여 반환
    /// - `419`: accessToken 만료, 자동으로 토큰 갱신 후 재시도
    /// - `418`: refreshToken 만료, 재로그인 필요
    /// - `400-499`: 클라이언트 에러, 서버의 에러 메시지를 포함한 `NetworkError.serverError` throw
    /// - `500-599`: 서버 에러, `NetworkError.internalServerError` throw
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // 로그인 요청
    /// let loginResponse = try await NetworkService.shared.request(
    ///     endpoint: APIRouter.login(email: "user@example.com", password: "password123"),
    ///     responseType: LoginResponse.self
    /// )
    ///
    /// // 유저 검색 요청
    /// let searchResponse = try await NetworkService.shared.request(
    ///     endpoint: APIRouter.searchUsers(query: "jack"),
    ///     responseType: UserSearchResponse.self
    /// )
    ///
    /// // 에러 처리
    /// do {
    ///     let response = try await NetworkService.shared.request(
    ///         endpoint: APIRouter.validateEmail(email: "test@example.com"),
    ///         responseType: EmailValidationResponse.self
    ///     )
    /// } catch NetworkError.networkFailure {
    ///     print("인터넷 연결을 확인해주세요")
    /// } catch NetworkError.serverError(let message) {
    ///     print("서버 에러: \(message)")
    /// } catch {
    ///     print("요청 실패: \(error)")
    /// }
    /// ```
    ///
    /// - Note: 이 메서드는 `async` 함수이므로 `await` 키워드와 함께 사용해야 합니다.
    /// - Important: 네트워크 요청 전에 자동으로 ``NetworkMonitor``를 통해 연결 상태를 확인합니다.
    func request<T: Decodable>(
        endpoint: Endpoint,
        responseType: T.Type
    ) async throws -> T {
        // 네트워크 연결 확인
        guard NetworkMonitor.shared.isConnected else {
            throw NetworkError.networkFailure
        }

        var request = try endpoint.asURLRequest()

        // Interceptor: adapt (요청 전 처리)
        for interceptor in interceptors {
            request = try await interceptor.adapt(request)
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            // 상태 코드에 따른 에러 생성
            if let error = handleHTTPStatusCode(httpResponse.statusCode, data: data) {
                throw error
            }

            // 성공 응답 디코딩
            do {
                let decodedData = try JSONDecoder().decode(T.self, from: data)
                return decodedData
            } catch {
                throw NetworkError.decodingError
            }

        } catch {
            // Interceptor: retry (에러 발생 시 재시도)
            for interceptor in interceptors {
                if try await interceptor.retry(request, dueTo: error) {
                    // 재시도
                    return try await self.request(endpoint: endpoint, responseType: responseType)
                }
            }

            // 재시도하지 않으면 에러 throw
            throw error
        }
    }

    /// 응답 본문 없이 API 요청만 수행합니다
    ///
    /// 응답 데이터가 필요하지 않은 API 요청에 사용합니다.
    /// HTTP 상태 코드만 확인하고 성공(200-299)인 경우 정상 종료합니다.
    ///
    /// - Parameter endpoint: 요청할 API 엔드포인트. `APIRouter` enum을 사용합니다.
    ///
    /// - Throws:
    ///   - `NetworkError.networkFailure`: 네트워크 연결이 없는 경우
    ///   - `NetworkError.invalidURL`: 잘못된 URL인 경우
    ///   - `NetworkError.invalidResponse`: 서버 응답이 유효하지 않은 경우
    ///   - `NetworkError.serverError(message:)`: 서버에서 에러를 반환한 경우 (400-499)
    ///   - `NetworkError.internalServerError`: 서버 내부 오류 (500-599)
    ///   - `NetworkError.unknown`: 알 수 없는 에러
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // 회원 탈퇴 요청 (응답 본문 불필요)
    /// do {
    ///     try await NetworkService.shared.requestWithoutResponse(
    ///         endpoint: APIRouter.withdraw
    ///     )
    ///     print("회원 탈퇴 성공")
    /// } catch {
    ///     print("회원 탈퇴 실패: \(error)")
    /// }
    ///
    /// // 팔로우/언팔로우 요청
    /// try await NetworkService.shared.requestWithoutResponse(
    ///     endpoint: APIRouter.followUser(userId: "user123")
    /// )
    /// ```
    ///
    /// - Note: 응답 본문이 있는 API에는 ``request(endpoint:responseType:)``를 사용하세요.
    func requestWithoutResponse(endpoint: Endpoint) async throws {
        // 네트워크 연결 확인
        guard NetworkMonitor.shared.isConnected else {
            throw NetworkError.networkFailure
        }

        var request = try endpoint.asURLRequest()

        // Interceptor: adapt (요청 전 처리)
        for interceptor in interceptors {
            request = try await interceptor.adapt(request)
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            // 상태 코드에 따른 에러 생성
            if let error = handleHTTPStatusCode(httpResponse.statusCode, data: data) {
                throw error
            }

        } catch {
            // Interceptor: retry (에러 발생 시 재시도)
            for interceptor in interceptors {
                if try await interceptor.retry(request, dueTo: error) {
                    // 재시도
                    return try await self.requestWithoutResponse(endpoint: endpoint)
                }
            }

            // 재시도하지 않으면 에러 throw
            throw error
        }
    }

    /// 서버 에러 응답에서 에러 메시지를 추출합니다
    ///
    /// 서버로부터 받은 에러 응답 데이터를 파싱하여 사용자에게 표시할 에러 메시지를 추출합니다.
    /// 파싱 실패 시 기본 에러 메시지를 반환합니다.
    ///
    /// - Parameter data: 서버 응답 데이터
    /// - Returns: 에러 메시지 문자열
    ///
    /// ## 서버 에러 응답 형식
    ///
    /// ```json
    /// {
    ///   "message": "이미 가입된 이메일입니다"
    /// }
    /// ```
    ///
    /// - Note: 이 메서드는 내부적으로만 사용되며, 외부에서 직접 호출하지 않습니다.
    private func parseErrorMessage(from data: Data) -> String {
        guard let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) else {
            return ErrorMessage.unknownError
        }
        return errorResponse.message
    }

    /// HTTP 상태 코드에 따라 에러를 반환합니다
    ///
    /// - Parameters:
    ///   - statusCode: HTTP 상태 코드
    ///   - data: 응답 데이터
    /// - Returns: 에러가 있으면 NetworkError, 성공이면 nil
    private func handleHTTPStatusCode(_ statusCode: Int, data: Data) -> NetworkError? {
        switch statusCode {
        case 200...299:
            return nil  // 성공
        case 419:
            return .tokenExpired  // AccessToken 만료
        case 418:
            // RefreshToken 만료 - 재로그인 필요
            let errorMessage = parseErrorMessage(from: data)
            return .serverError(message: errorMessage)
        case 400...499:
            // 클라이언트 에러
            let errorMessage = parseErrorMessage(from: data)
            return .serverError(message: errorMessage)
        case 500...599:
            return .internalServerError  // 서버 내부 오류
        default:
            return .unknown
        }
    }

}

/// 에러 메시지 상수
private enum ErrorMessage {
    static let unknownError = "알 수 없는 오류가 발생했습니다"
}
