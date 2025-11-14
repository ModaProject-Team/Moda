//
//  APIRouter.swift
//  Moda
//
//  Created by 금가경 on 11/12/24.
//

import Foundation

/// 서버 API 엔드포인트를 정의하는 라우터
///
/// `APIRouter`는 애플리케이션의 모든 API 엔드포인트를 중앙에서 관리하는 enum입니다.
/// 각 케이스는 하나의 API 엔드포인트를 나타내며, ``Endpoint`` 프로토콜을 준수합니다.
///
/// ## Overview
///
/// APIRouter는 다음과 같은 역할을 수행합니다:
/// - API 엔드포인트의 경로, 메서드, 파라미터 정의
/// - Type-safe한 API 호출 보장
/// - 중앙 집중식 API 관리
///
/// ## API 카테고리
///
/// ### Log
/// - ``getLogs``: 서버 로그 조회 (디버깅용)
///
/// ### User Authentication
/// - ``validateEmail(email:)``: 이메일 중복 확인
/// - ``signUp(email:password:nickname:)``: 회원가입
/// - ``login(email:password:)``: 이메일 로그인
/// - ``loginKakao(token:)``: 카카오 로그인
/// - ``loginApple(token:)``: 애플 로그인
/// - ``withdraw``: 회원 탈퇴
///
/// ### User Search
/// - ``searchUsers(query:)``: 유저 검색
///
/// ## Usage
///
/// ### 기본 사용법
///
/// ```swift
/// // 1. 로그인
/// let loginResponse = try await NetworkService.shared.request(
///     endpoint: APIRouter.login(
///         email: "test@example.com",
///         password: "password123"
///     ),
///     responseType: LoginResponse.self
/// )
///
/// // 2. 유저 검색
/// let searchResponse = try await NetworkService.shared.request(
///     endpoint: APIRouter.searchUsers(query: "jack"),
///     responseType: UserSearchResponse.self
/// )
///
/// // 3. 회원 탈퇴 (응답 없음)
/// try await NetworkService.shared.requestWithoutResponse(
///     endpoint: APIRouter.withdraw
/// )
/// ```
///
/// ### 새로운 API 추가하기
///
/// ```swift
/// // 1. APIRouter에 케이스 추가
/// enum APIRouter {
///     // ...
///     case getMyProfile
///     case updateProfile(nick: String?, phoneNum: String?)
/// }
///
/// // 2. Endpoint 프로토콜 구현
/// extension APIRouter: Endpoint {
///     var path: String {
///         switch self {
///         // ...
///         case .getMyProfile, .updateProfile:
///             return "/v1/users/me/profile"
///         }
///     }
///
///     var method: HTTPMethod {
///         switch self {
///         case .getMyProfile:
///             return .get
///         case .updateProfile:
///             return .put
///         // ...
///         }
///     }
///
///     var parameters: [String: Any]? {
///         switch self {
///         case .updateProfile(let nick, let phoneNum):
///             var params: [String: Any] = [:]
///             if let nick = nick { params["nick"] = nick }
///             if let phoneNum = phoneNum { params["phoneNum"] = phoneNum }
///             return params.isEmpty ? nil : params
///         default:
///             return nil
///         }
///     }
/// }
///
/// // 3. DTO 정의
/// struct ProfileResponse: Decodable {
///     let userId: String
///     let nick: String
///     // ...
/// }
///
/// // 4. 사용
/// let profile = try await NetworkService.shared.request(
///     endpoint: APIRouter.getMyProfile,
///     responseType: ProfileResponse.self
/// )
/// ```
///
/// ## Topics
///
/// ### Log API
/// - ``getLogs``
///
/// ### Authentication API
/// - ``validateEmail(email:)``
/// - ``signUp(email:password:nickname:)``
/// - ``login(email:password:)``
/// - ``loginKakao(token:)``
/// - ``loginApple(token:)``
/// - ``withdraw``
///
/// ### User API
/// - ``searchUsers(query:)``
///
/// ### Endpoint 구현
/// - ``baseURL``
/// - ``path``
/// - ``method``
/// - ``headers``
/// - ``parameters``
/// - ``queryItems``
///
/// - SeeAlso: ``Endpoint``, ``NetworkService``, ``HTTPMethod``
/// - Note: 모든 API는 ``NetworkService``를 통해 호출됩니다.
/// - Important: 새로운 API 추가 시 케이스 정의와 Endpoint 프로토콜 구현이 모두 필요합니다.
enum APIRouter {

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
    ///     endpoint: APIRouter.getLogs,
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

    /// 이메일 중복 확인
    ///
    /// 회원가입 전에 이메일이 이미 사용 중인지 확인합니다.
    ///
    /// - Parameter email: 검증할 이메일 주소
    /// - Returns: ``EmailValidationResponse`` - 검증 결과 메시지
    ///
    /// ## HTTP 요청 상세
    /// - Method: POST
    /// - Path: `/v1/users/validation/email`
    /// - Body: `{"email": "test@example.com"}`
    ///
    /// ## 중복 체크 규칙
    /// - ProductId와 상관없이 email은 전체 서비스에서 중복체크됩니다
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let response = try await NetworkService.shared.request(
    ///     endpoint: APIRouter.validateEmail(email: "test@example.com"),
    ///     responseType: EmailValidationResponse.self
    /// )
    /// print(response.message) // "사용 가능한 이메일입니다"
    /// ```
    ///
    /// ## 에러 처리
    ///
    /// ```swift
    /// do {
    ///     let response = try await NetworkService.shared.request(
    ///         endpoint: APIRouter.validateEmail(email: email),
    ///         responseType: EmailValidationResponse.self
    ///     )
    ///     // 사용 가능
    /// } catch NetworkError.serverError(let message) {
    ///     // message: "이미 가입된 이메일입니다"
    ///     showError(message)
    /// }
    /// ```
    case validateEmail(email: String)

    /// 회원가입
    ///
    /// 새로운 사용자 계정을 생성합니다.
    ///
    /// - Parameters:
    ///   - email: 이메일 주소 (로그인 ID로 사용)
    ///   - password: 비밀번호 (8자 이상 권장)
    ///   - nickname: 사용자 닉네임
    ///
    /// - Returns: ``SignUpResponse`` - 생성된 사용자 정보
    ///
    /// ## HTTP 요청 상세
    /// - Method: POST
    /// - Path: `/v1/users/join`
    /// - Body: `{"email": "...", "password": "...", "nick": "..."}`
    ///
    /// ## ProductId 규칙
    /// - header의 ProductId로 회원가입이 됩니다
    /// - `. , ? * - @ + ^ $ { } ( ) | [ ] \`는 ProductId에 포함될 수 없습니다
    /// - ProductId에 공백과 빈 문자열은 포함될 수 없습니다
    ///
    /// ## 이메일 중복 체크
    /// - ProductId와 상관없이 email은 전체 서비스에서 중복체크됩니다
    ///
    /// ## 닉네임 규칙
    /// - nick은 공백을 포함하거나, 빈 문자열로 설정할 수 없습니다
    /// - `. , ? * - @ + ^ $ { } ( ) | [ ] \`는 nick에 포함할 수 없습니다
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let response = try await NetworkService.shared.request(
    ///     endpoint: APIRouter.signUp(
    ///         email: "user@example.com",
    ///         password: "password123!",
    ///         nickname: "홍길동"
    ///     ),
    ///     responseType: SignUpResponse.self
    /// )
    ///
    /// print("회원가입 성공!")
    /// print("User ID: \(response.userId)")
    /// print("Email: \(response.email)")
    /// ```
    ///
    /// ## 주의사항
    /// - 회원가입 후 별도로 로그인해야 합니다
    /// - 이메일 중복 확인을 먼저 수행하는 것을 권장합니다
    ///
    /// - SeeAlso: ``validateEmail(email:)``
    case signUp(email: String, password: String, nickname: String)

    /// 이메일 로그인
    ///
    /// 이메일과 비밀번호로 로그인하여 액세스 토큰을 발급받습니다.
    ///
    /// - Parameters:
    ///   - email: 등록된 이메일 주소
    ///   - password: 계정 비밀번호
    ///
    /// - Returns: ``LoginResponse`` - 사용자 정보 및 인증 토큰
    ///
    /// ## HTTP 요청 상세
    /// - Method: POST
    /// - Path: `/v1/users/login`
    /// - Body: `{"email": "...", "password": "..."}`
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let response = try await NetworkService.shared.request(
    ///     endpoint: APIRouter.login(
    ///         email: "user@example.com",
    ///         password: "password123!"
    ///     ),
    ///     responseType: LoginResponse.self
    /// )
    ///
    /// // 토큰 저장 (자동으로 이후 요청에 사용됨)
    /// TokenManager.shared.saveToken(accessToken: response.accessToken)
    ///
    /// print("로그인 성공!")
    /// print("사용자: \(response.nick)")
    /// ```
    ///
    /// ## 토큰 관리
    /// 로그인 성공 후 ``TokenManager``에 토큰을 저장하면,
    /// 이후 모든 API 요청에 자동으로 Authorization 헤더가 추가됩니다.
    ///
    /// - Important: 로그인 성공 후 반드시 토큰을 저장해야 인증이 필요한 API를 호출할 수 있습니다.
    case login(email: String, password: String)

    /// 카카오 로그인
    ///
    /// 카카오 OAuth 토큰으로 로그인합니다.
    ///
    /// - Parameter token: 카카오에서 발급받은 ID 토큰
    /// - Returns: ``LoginResponse`` - 사용자 정보 및 인증 토큰
    ///
    /// ## HTTP 요청 상세
    /// - Method: POST
    /// - Path: `/v1/users/login/kakao`
    /// - Body: `{"idToken": "..."}`
    ///
    /// ## 최초 카카오 로그인 (자동 회원가입)
    /// - header의 ProductId로 회원가입이 됩니다
    /// - `. , ? * - @ + ^ $ { } ( ) | [ ] \`는 ProductId에 포함될 수 없습니다
    /// - ProductId에 공백과 빈 문자열은 포함될 수 없습니다
    /// - ProductId와 상관없이 email은 전체 서비스에서 중복체크됩니다
    /// - 닉네임은 서버에서 '새싹이00000' 형식으로 자동 생성됩니다 (0는 영문 대소문자 또는 숫자 5자리)
    ///
    /// ## 기존 계정 처리
    /// - 다른 수단으로 회원가입이 된 계정인 경우 중복 계정으로 처리되어 회원가입을 할 수 없습니다
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // 1. 카카오 SDK로 로그인하여 토큰 획득
    /// let kakaoToken = ... // 카카오 SDK에서 받은 토큰
    ///
    /// // 2. 서버에 카카오 로그인 요청
    /// let response = try await NetworkService.shared.request(
    ///     endpoint: APIRouter.loginKakao(token: kakaoToken),
    ///     responseType: LoginResponse.self
    /// )
    ///
    /// // 3. 토큰 저장
    /// TokenManager.shared.saveToken(accessToken: response.accessToken)
    /// ```
    ///
    /// - Note: 카카오 SDK 구현 후 사용 가능합니다.
    case loginKakao(token: String)

    /// 애플 로그인
    ///
    /// 애플 OAuth 토큰으로 로그인합니다.
    ///
    /// - Parameter token: 애플에서 발급받은 ID 토큰
    /// - Returns: ``LoginResponse`` - 사용자 정보 및 인증 토큰
    ///
    /// ## HTTP 요청 상세
    /// - Method: POST
    /// - Path: `/v1/users/login/apple`
    /// - Body: `{"idToken": "..."}`
    ///
    /// ## 최초 애플 로그인 (자동 회원가입)
    /// - header의 ProductId로 회원가입이 됩니다
    /// - `. , ? * - @ + ^ $ { } ( ) | [ ] \`는 ProductId에 포함될 수 없습니다
    /// - ProductId에 공백과 빈 문자열은 포함될 수 없습니다
    /// - ProductId와 상관없이 email은 중복체크됩니다
    /// - 닉네임은 서버에서 '새싹이00000' 형식으로 자동 생성됩니다 (0는 영문 대소문자 또는 숫자 5자리)
    ///
    /// ## 기존 계정 처리
    /// - 다른 수단으로 회원가입이 된 계정인 경우 중복 계정으로 처리되어 회원가입을 할 수 없습니다
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // 1. Sign in with Apple로 토큰 획득
    /// let appleToken = ... // Apple에서 받은 토큰
    ///
    /// // 2. 서버에 애플 로그인 요청
    /// let response = try await NetworkService.shared.request(
    ///     endpoint: APIRouter.loginApple(token: appleToken),
    ///     responseType: LoginResponse.self
    /// )
    ///
    /// // 3. 토큰 저장
    /// TokenManager.shared.saveToken(accessToken: response.accessToken)
    /// ```
    ///
    /// - Note: Sign in with Apple 구현 후 사용 가능합니다.
    case loginApple(token: String)

    /// 회원 탈퇴
    ///
    /// 현재 로그인한 사용자의 계정을 삭제합니다.
    ///
    /// - Returns: ``WithdrawResponse`` - 탈퇴한 사용자 정보
    ///
    /// ## HTTP 요청 상세
    /// - Method: GET
    /// - Path: `/v1/users/withdraw`
    /// - Auth: 필수 (액세스 토큰)
    ///
    /// ## 데이터 삭제
    /// - 회원탈퇴 시 작성한 게시글, 댓글/대댓글, 팔로우 내역 등 모든 데이터가 삭제됩니다
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // 회원 탈퇴
    /// let response = try await NetworkService.shared.request(
    ///     endpoint: APIRouter.withdraw,
    ///     responseType: WithdrawResponse.self
    /// )
    ///
    /// // 토큰 삭제
    /// TokenManager.shared.clearToken()
    ///
    /// print("회원 탈퇴 완료")
    /// print("탈퇴 계정: \(response.email)")
    /// ```
    ///
    /// ## 주의사항
    /// - 회원 탈퇴는 되돌릴 수 없습니다
    /// - 탈퇴 후 저장된 토큰을 삭제해야 합니다
    /// - 사용자에게 확인 팝업을 표시하는 것을 권장합니다
    ///
    /// - Important: 이 작업은 되돌릴 수 없으므로 신중하게 수행해야 합니다.
    case withdraw

    /// 유저 검색
    ///
    /// 닉네임으로 사용자를 검색합니다.
    ///
    /// - Parameter query: 검색할 닉네임 (부분 일치 검색)
    /// - Returns: ``UserSearchResponse`` - 검색된 사용자 목록
    ///
    /// ## HTTP 요청 상세
    /// - Method: GET
    /// - Path: `/v1/users/search?query=검색어`
    /// - Auth: 필수 (액세스 토큰)
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // 닉네임에 "jack"이 포함된 사용자 검색
    /// let response = try await NetworkService.shared.request(
    ///     endpoint: APIRouter.searchUsers(query: "jack"),
    ///     responseType: UserSearchResponse.self
    /// )
    ///
    /// print("검색 결과: \(response.data.count)명")
    /// for user in response.data {
    ///     print("- \(user.nick) (ID: \(user.userId))")
    /// }
    /// ```
    ///
    /// ## 검색 팁
    /// - 검색어는 대소문자를 구분하지 않습니다
    /// - 부분 일치 검색을 지원합니다
    /// - 빈 문자열로 검색하면 모든 사용자를 반환합니다
    ///
    /// - Note: 로그인 상태에서만 사용할 수 있습니다.
    case searchUsers(query: String)
}

extension APIRouter: Endpoint {

    var baseURL: String {
        NetworkConfig.baseURL
    }

    var path: String {
        switch self {
        case .getLogs:
            return "/v1/logs"
        case .validateEmail:
            return "/v1/users/validation/email"
        case .signUp:
            return "/v1/users/join"
        case .login:
            return "/v1/users/login"
        case .loginKakao:
            return "/v1/users/login/kakao"
        case .loginApple:
            return "/v1/users/login/apple"
        case .withdraw:
            return "/v1/users/withdraw"
        case .searchUsers:
            return "/v1/users/search"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .validateEmail, .signUp, .login, .loginKakao, .loginApple:
            return .post
        case .getLogs, .withdraw, .searchUsers:
            return .get
        }
    }

    var headers: [String: String]? {
        var headers = ["Content-Type": "application/json"]

        headers["SesacKey"] = NetworkConfig.sesacKey
        headers["ProductId"] = NetworkConfig.productId

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
            return ["idToken": token]
        default:
            return nil
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .searchUsers(let query):
            return [URLQueryItem(name: "query", value: query)]
        default:
            return nil
        }
    }
}
