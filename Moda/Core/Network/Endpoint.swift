//
//  Endpoint.swift
//  Moda
//
//  Created by 금가경 on 11/12/24.
//

import Foundation

/// API 엔드포인트를 정의하는 프로토콜
///
/// `Endpoint` 프로토콜은 RESTful API 요청을 구성하는 데 필요한 모든 정보를 제공합니다.
/// 이 프로토콜을 준수하는 타입은 자동으로 `URLRequest`로 변환될 수 있습니다.
///
/// ## Overview
///
/// 엔드포인트는 다음 요소들로 구성됩니다:
/// - Base URL: API 서버의 기본 주소
/// - Path: API 리소스 경로
/// - HTTP Method: 요청 메서드 (GET, POST, PUT, DELETE)
/// - Headers: HTTP 헤더 (인증, Content-Type 등)
/// - Parameters: 요청 바디 (POST/PUT용)
/// - Query Items: URL 쿼리 파라미터 (GET용)
///
/// ## Usage
///
/// ### 엔드포인트 정의
///
/// ```swift
/// enum APIRouter {
///     case login(email: String, password: String)
///     case getUsers(query: String)
/// }
///
/// extension APIRouter: Endpoint {
///     var baseURL: String {
///         return "https://api.example.com"
///     }
///
///     var path: String {
///         switch self {
///         case .login:
///             return "/v1/users/login"
///         case .getUsers:
///             return "/v1/users"
///         }
///     }
///
///     var method: HTTPMethod {
///         switch self {
///         case .login:
///             return .post
///         case .getUsers:
///             return .get
///         }
///     }
///
///     var parameters: [String: Any]? {
///         switch self {
///         case .login(let email, let password):
///             return ["email": email, "password": password]
///         default:
///             return nil
///         }
///     }
///
///     var queryItems: [URLQueryItem]? {
///         switch self {
///         case .getUsers(let query):
///             return [URLQueryItem(name: "query", value: query)]
///         default:
///             return nil
///         }
///     }
/// }
/// ```
///
/// ### URLRequest 변환
///
/// ```swift
/// let endpoint = APIRouter.login(email: "test@example.com", password: "password")
/// let request = try endpoint.asURLRequest()
///
/// // 자동으로 구성된 URLRequest:
/// // - URL: https://api.example.com/v1/users/login
/// // - Method: POST
/// // - Headers: Authorization, Content-Type
/// // - Body: {"email": "test@example.com", "password": "password"}
/// ```
///
/// ## Topics
///
/// ### 필수 프로퍼티
/// - ``baseURL``
/// - ``path``
/// - ``method``
/// - ``headers``
/// - ``parameters``
/// - ``queryItems``
///
/// ### URLRequest 변환
/// - ``asURLRequest()``
///
/// - Note: 이 프로토콜은 ``APIRouter``에서 구현됩니다.
/// - Important: ``asURLRequest()``는 자동으로 인증 토큰을 헤더에 추가합니다.
protocol Endpoint {

    /// API 서버의 기본 URL
    ///
    /// 모든 API 요청의 시작점이 되는 서버 주소입니다.
    /// 프로토콜(https://)을 포함한 전체 도메인을 반환해야 합니다.
    ///
    /// ## Example
    ///
    /// ```swift
    /// var baseURL: String {
    ///     return "https://api.example.com"
    /// }
    /// ```
    ///
    /// - Note: 일반적으로 ``NetworkConfig``에 정의된 값을 사용합니다.
    var baseURL: String { get }

    /// API 리소스 경로
    ///
    /// baseURL 뒤에 붙는 API 엔드포인트의 경로입니다.
    /// 슬래시(/)로 시작해야 하며, 버전 정보를 포함합니다.
    ///
    /// ## Example
    ///
    /// ```swift
    /// var path: String {
    ///     switch self {
    ///     case .login:
    ///         return "/v1/users/login"
    ///     case .getUserProfile(let userId):
    ///         return "/v1/users/\(userId)/profile"
    ///     }
    /// }
    /// ```
    var path: String { get }

    /// HTTP 메서드
    ///
    /// 요청에 사용할 HTTP 메서드를 정의합니다.
    ///
    /// ## 메서드 선택 가이드
    /// - `.get`: 데이터 조회
    /// - `.post`: 새 리소스 생성, 로그인 등
    /// - `.put`: 전체 리소스 업데이트
    /// - `.delete`: 리소스 삭제
    ///
    /// ## Example
    ///
    /// ```swift
    /// var method: HTTPMethod {
    ///     switch self {
    ///     case .getUsers:
    ///         return .get
    ///     case .createPost:
    ///         return .post
    ///     }
    /// }
    /// ```
    ///
    /// - SeeAlso: ``HTTPMethod``
    var method: HTTPMethod { get }

    /// HTTP 요청 헤더
    ///
    /// API 요청에 포함될 HTTP 헤더들을 정의합니다.
    /// 인증 토큰은 ``asURLRequest()``에서 자동으로 추가되므로 포함하지 않습니다.
    ///
    /// ## 일반적인 헤더
    /// - `Content-Type`: 요청 바디의 형식 (예: "application/json")
    /// - `SesacKey`: API 키
    /// - `ProductId`: 프로덕트 ID
    ///
    /// ## Example
    ///
    /// ```swift
    /// var headers: [String: String]? {
    ///     return [
    ///         "Content-Type": "application/json",
    ///         "SesacKey": NetworkConfig.sesacKey
    ///     ]
    /// }
    /// ```
    ///
    /// - Note: 인증 토큰은 ``TokenManager``에서 자동으로 주입됩니다.
    var headers: [String: String]? { get }

    /// 요청 바디 파라미터
    ///
    /// POST/PUT 요청 시 서버로 전송할 데이터를 정의합니다.
    /// JSON 형식으로 자동 직렬화되어 요청 바디에 포함됩니다.
    ///
    /// ## Example
    ///
    /// ```swift
    /// var parameters: [String: Any]? {
    ///     switch self {
    ///     case .login(let email, let password):
    ///         return [
    ///             "email": email,
    ///             "password": password
    ///         ]
    ///     case .signUp(let email, let password, let nickname):
    ///         return [
    ///             "email": email,
    ///             "password": password,
    ///             "nick": nickname
    ///         ]
    ///     default:
    ///         return nil
    ///     }
    /// }
    /// ```
    ///
    /// - Note: GET 요청에는 일반적으로 nil을 반환합니다.
    var parameters: [String: Any]? { get }

    /// URL 쿼리 파라미터
    ///
    /// URL에 포함될 쿼리 스트링 파라미터를 정의합니다.
    /// GET 요청에서 검색, 필터링, 페이지네이션 등에 사용됩니다.
    ///
    /// ## Example
    ///
    /// ```swift
    /// var queryItems: [URLQueryItem]? {
    ///     switch self {
    ///     case .searchUsers(let query):
    ///         return [URLQueryItem(name: "query", value: query)]
    ///     case .getPosts(let limit, let cursor):
    ///         var items: [URLQueryItem] = []
    ///         if let limit = limit {
    ///             items.append(URLQueryItem(name: "limit", value: limit))
    ///         }
    ///         if let cursor = cursor {
    ///             items.append(URLQueryItem(name: "cursor", value: cursor))
    ///         }
    ///         return items.isEmpty ? nil : items
    ///     default:
    ///         return nil
    ///     }
    /// }
    /// ```
    ///
    /// - Note: 쿼리 파라미터는 자동으로 URL 인코딩됩니다.
    var queryItems: [URLQueryItem]? { get }
}

extension Endpoint {
    /// Endpoint를 URLRequest로 변환합니다
    ///
    /// 이 메서드는 Endpoint 프로토콜의 모든 프로퍼티를 사용하여
    /// 실제 네트워크 요청에 사용할 수 있는 `URLRequest` 객체를 생성합니다.
    ///
    /// ## 자동 처리 기능
    ///
    /// 1. **URL 구성**: baseURL + path + queryItems
    /// 2. **헤더 설정**: 제공된 헤더 + Authorization 헤더 (토큰 있을 경우)
    /// 3. **바디 설정**: parameters를 JSON으로 직렬화
    /// 4. **Content-Type**: parameters가 있으면 자동으로 "application/json" 설정
    ///
    /// ## 인증 토큰 자동 추가
    ///
    /// ``TokenManager``에 저장된 액세스 토큰이 있으면 자동으로 Authorization 헤더에 추가됩니다.
    /// 별도의 토큰 관리 코드가 필요하지 않습니다.
    ///
    /// - Returns: 네트워크 요청에 사용할 수 있는 `URLRequest` 객체
    ///
    /// - Throws: `NetworkError.invalidURL` - URL 구성 실패 시
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // 일반적으로 직접 호출하지 않고 NetworkService에서 사용됩니다
    /// let endpoint = APIRouter.login(email: "test@example.com", password: "password")
    /// let request = try endpoint.asURLRequest()
    ///
    /// // 생성된 request는 다음을 포함합니다:
    /// // - URL: https://api.example.com/v1/users/login
    /// // - Method: POST
    /// // - Headers: Content-Type, Authorization (토큰 있을 경우)
    /// // - Body: {"email": "test@example.com", "password": "password"}
    /// ```
    ///
    /// ## 에러 처리
    ///
    /// ```swift
    /// do {
    ///     let request = try endpoint.asURLRequest()
    ///     // 요청 수행
    /// } catch NetworkError.invalidURL {
    ///     print("잘못된 URL 형식입니다")
    /// }
    /// ```
    ///
    /// - Note: 이 메서드는 ``NetworkService``에서 내부적으로 호출됩니다.
    /// - Important: URL이 유효하지 않으면 ``NetworkError/invalidURL`` 에러를 throw합니다.
    func asURLRequest() throws -> URLRequest {
        guard var urlComponents = URLComponents(string: baseURL + path) else {
            throw NetworkError.invalidURL
        }

        if let queryItems = queryItems {
            urlComponents.queryItems = queryItems
        }

        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        if let headers = headers {
            headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        }

        if let parameters = parameters {
            request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return request
    }
}
