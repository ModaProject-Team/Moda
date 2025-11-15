//
//  NetworkError.swift
//  Moda
//
//  Created by 금가경 on 11/12/24.
//

import Foundation

/// 서버 에러 응답 DTO
///
/// 서버에서 반환하는 에러 응답의 구조를 정의합니다.
/// HTTP 상태 코드 400-499 범위의 클라이언트 에러 발생 시 이 형식으로 응답됩니다.
///
/// ## 서버 응답 형식
///
/// ```json
/// {
///   "message": "이미 가입된 이메일입니다"
/// }
/// ```
///
/// ## Usage
///
/// ```swift
/// // NetworkService 내부에서 자동으로 파싱됨
/// let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
/// throw NetworkError.serverError(message: errorResponse.message)
/// ```
///
/// - Note: 이 구조체는 ``NetworkService``에서 내부적으로 사용되며, 직접 사용할 필요가 없습니다.
struct ErrorResponse: Decodable {
    /// 서버에서 반환한 에러 메시지
    let message: String
}

/// 네트워크 요청 중 발생할 수 있는 모든 에러를 정의합니다
///
/// `NetworkError`는 HTTP 통신 과정에서 발생하는 다양한 에러 상황을 표현하는 enum입니다.
/// `LocalizedError` 프로토콜을 준수하여 사용자에게 표시할 수 있는 에러 메시지를 제공합니다.
///
/// ## Overview
///
/// 네트워크 요청 실패 시 다음과 같은 에러가 throw됩니다:
/// - 클라이언트 에러 (400-499): ``serverError(message:)``
/// - 서버 에러 (500-599): ``internalServerError``
/// - 네트워크 문제: ``networkFailure``, ``timeout``
/// - 구현 문제: ``invalidURL``, ``invalidResponse``, ``decodingError``
///
/// ## Usage
///
/// ### 에러 처리 예제
///
/// ```swift
/// do {
///     let response = try await NetworkService.shared.request(
///         endpoint: APIRouter.login(email: email, password: password),
///         responseType: LoginResponse.self
///     )
///     // 성공 처리
/// } catch let error as NetworkError {
///     switch error {
///     case .serverError(let message):
///         // 서버가 반환한 에러 메시지 표시
///         showAlert(message: message)
///     case .networkFailure:
///         // 네트워크 연결 확인 요청
///         showAlert(message: "인터넷 연결을 확인해주세요")
///     case .decodingError:
///         // 개발자에게 알림 (데이터 구조 문제)
///         reportToDeveloper(error: error)
///     default:
///         // 일반 에러 처리
///         showAlert(message: error.localizedDescription)
///     }
/// }
/// ```
///
/// ### 특정 에러만 처리
///
/// ```swift
/// do {
///     try await NetworkService.shared.request(
///         endpoint: APIRouter.validateEmail(email: email),
///         responseType: EmailValidationResponse.self
///     )
/// } catch NetworkError.serverError(let message) {
///     // 이메일 중복 등의 서버 에러만 처리
///     emailErrorLabel.text = message
/// } catch {
///     // 기타 에러
///     showGeneralError()
/// }
/// ```
///
/// ## Topics
///
/// ### 에러 케이스
/// - ``serverError(message:)`` - 클라이언트 에러 (400-499)
/// - ``invalidURL``
/// - ``invalidResponse``
/// - ``decodingError``
/// - ``internalServerError`` - 서버 에러 (500-599)
/// - ``networkFailure``
/// - ``timeout``
/// - ``unknown``
///
/// ### 에러 메시지
/// - ``errorDescription``
enum NetworkError: LocalizedError {

    /// 서버에서 반환한 클라이언트 에러 (HTTP 400-499)
    ///
    /// 잘못된 요청, 인증 실패, 리소스 없음 등 클라이언트 측 문제로 발생하는 에러입니다.
    /// 서버가 제공하는 구체적인 에러 메시지가 포함됩니다.
    ///
    /// - Parameter message: 서버에서 반환한 에러 메시지 (예: "이미 가입된 이메일입니다")
    ///
    /// ## 발생 상황
    /// - 이메일 중복 (회원가입 시)
    /// - 잘못된 비밀번호 (로그인 시)
    /// - 존재하지 않는 리소스 요청
    /// - 권한 없는 접근 시도
    ///
    /// ## Usage
    ///
    /// ```swift
    /// catch NetworkError.serverError(let message) {
    ///     // 사용자에게 서버의 에러 메시지를 그대로 표시
    ///     alertLabel.text = message
    /// }
    /// ```
    case serverError(message: String)

    /// 잘못된 URL 형식
    ///
    /// API 엔드포인트의 URL이 유효하지 않을 때 발생합니다.
    ///
    /// ## 발생 상황
    /// - baseURL 또는 path가 잘못 설정된 경우
    /// - URL 구성 요소에 잘못된 문자가 포함된 경우
    ///
    /// - Note: 이 에러는 개발 단계에서 발견되어야 하며, 프로덕션에서는 발생하지 않아야 합니다.
    case invalidURL

    /// 잘못된 서버 응답
    ///
    /// 서버 응답이 HTTPURLResponse로 캐스팅되지 않을 때 발생합니다.
    ///
    /// ## 발생 상황
    /// - 서버가 HTTP 프로토콜을 따르지 않는 응답을 보낸 경우
    /// - 네트워크 계층에서 비정상적인 응답을 받은 경우
    ///
    /// - Note: 매우 드물게 발생하는 에러입니다.
    case invalidResponse

    /// JSON 디코딩 실패
    ///
    /// 서버 응답 데이터를 지정된 타입으로 디코딩하는 데 실패했을 때 발생합니다.
    ///
    /// ## 발생 상황
    /// - 서버 응답 JSON 구조가 DTO 정의와 다른 경우
    /// - 필수 필드가 누락된 경우
    /// - 데이터 타입이 맞지 않는 경우
    ///
    /// ## 디버깅
    ///
    /// ```swift
    /// catch NetworkError.decodingError {
    ///     // 개발 중: 서버 응답 원본 확인 필요
    ///     print("서버 응답과 DTO 구조를 확인하세요")
    /// }
    /// ```
    ///
    /// - Important: 이 에러 발생 시 DTO 정의를 확인하고 서버 API 명세와 일치하는지 검증해야 합니다.
    case decodingError

    /// 서버 내부 오류 (HTTP 500-599)
    ///
    /// 서버 측 문제로 요청을 처리할 수 없을 때 발생합니다.
    ///
    /// ## 발생 상황
    /// - 서버 프로그램 오류
    /// - 데이터베이스 연결 실패
    /// - 서버 과부하
    ///
    /// ## 사용자 대응
    /// - "서버에 일시적인 문제가 발생했습니다. 잠시 후 다시 시도해주세요"
    case internalServerError

    /// 네트워크 연결 실패
    ///
    /// 인터넷 연결이 없거나 네트워크 상태가 불안정할 때 발생합니다.
    ///
    /// ## 발생 상황
    /// - Wi-Fi/모바일 데이터 연결이 끊긴 경우
    /// - 비행기 모드 활성화
    /// - 네트워크 신호가 약한 경우
    ///
    /// ## 사용자 대응
    /// - 네트워크 연결 상태 확인 요청
    /// - 설정에서 Wi-Fi/모바일 데이터 확인 안내
    ///
    /// - Note: ``NetworkMonitor``를 통해 요청 전에 미리 확인됩니다.
    case networkFailure

    /// 요청 시간 초과
    ///
    /// 설정된 타임아웃 시간(30초) 내에 서버 응답을 받지 못했을 때 발생합니다.
    ///
    /// ## 발생 상황
    /// - 서버 응답이 너무 느린 경우
    /// - 네트워크 속도가 매우 느린 경우
    ///
    /// - Note: 현재 타임아웃은 ``NetworkService``에서 30초로 설정되어 있습니다.
    case timeout

    /// 알 수 없는 에러
    ///
    /// 위의 정의된 에러 케이스에 해당하지 않는 예외적인 상황입니다.
    ///
    /// - Note: 이 에러가 자주 발생한다면 새로운 에러 케이스 추가를 고려해야 합니다.
    case unknown

    /// 사용자에게 표시할 에러 메시지
    ///
    /// 각 에러 케이스에 대한 한글 에러 메시지를 반환합니다.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// catch let error as NetworkError {
    ///     // 에러 메시지를 UI에 표시
    ///     showAlert(message: error.localizedDescription)
    /// }
    /// ```
    var errorDescription: String? {
        switch self {
        case .serverError(let message):
            return message
        case .invalidURL:
            return "잘못된 URL입니다"
        case .invalidResponse:
            return "서버 응답이 올바르지 않습니다"
        case .decodingError:
            return "데이터 처리 중 오류가 발생했습니다"
        case .internalServerError:
            return "서버 내부 오류가 발생했습니다"
        case .networkFailure:
            return "네트워크 연결에 실패했습니다"
        case .timeout:
            return "요청 시간이 초과되었습니다"
        case .unknown:
            return "알 수 없는 오류가 발생했습니다"
        }
    }
}
