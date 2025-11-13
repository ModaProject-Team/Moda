//
//  HTTPMethod.swift
//  Moda
//
//  Created by 금가경 on 11/12/24.
//

import Foundation

/// HTTP 요청 메서드를 정의하는 열거형
///
/// RESTful API에서 사용되는 표준 HTTP 메서드들을 정의합니다.
/// 각 메서드는 특정 작업 유형과 연관되어 있습니다.
///
/// ## Overview
///
/// HTTP 메서드는 서버에 어떤 작업을 수행할지 알려주는 역할을 합니다.
/// RESTful API 설계 원칙에 따라 적절한 메서드를 선택해야 합니다.
///
/// ## 메서드별 용도
///
/// | 메서드 | 용도 | 멱등성 | 안전성 |
/// |--------|------|--------|--------|
/// | GET    | 조회 | O      | O      |
/// | POST   | 생성 | X      | X      |
/// | PUT    | 전체 수정 | O | X |
/// | DELETE | 삭제 | O      | X      |
///
/// - **멱등성(Idempotent)**: 같은 요청을 여러 번 해도 결과가 동일
/// - **안전성(Safe)**: 서버 상태를 변경하지 않음
///
/// ## Usage
///
/// ### APIRouter에서 사용
///
/// ```swift
/// extension APIRouter: Endpoint {
///     var method: HTTPMethod {
///         switch self {
///         case .getUsers, .getUserProfile, .searchUsers:
///             return .get
///         case .login, .signUp, .createPost:
///             return .post
///         case .updateProfile, .updatePost:
///             return .put
///         case .deletePost, .withdraw:
///             return .delete
///         }
///     }
/// }
/// ```
///
/// ### 직접 사용 (일반적이지 않음)
///
/// ```swift
/// let method: HTTPMethod = .get
/// print(method.rawValue) // "GET"
/// ```
///
/// ## 메서드 선택 가이드
///
/// ### GET
/// - 리소스 조회
/// - 서버 상태 변경 없음
/// - 캐싱 가능
/// - 예: 사용자 목록, 프로필 조회
///
/// ### POST
/// - 새 리소스 생성
/// - 로그인, 회원가입
/// - 파일 업로드
/// - 예: 게시글 작성, 로그인
///
/// ### PUT
/// - 리소스 전체 업데이트
/// - 멱등성 보장
/// - 예: 프로필 수정, 게시글 전체 수정
///
/// ### DELETE
/// - 리소스 삭제
/// - 멱등성 보장
/// - 예: 회원 탈퇴, 게시글 삭제
///
/// ## Topics
///
/// ### HTTP 메서드
/// - ``get``
/// - ``post``
/// - ``put``
/// - ``delete``
///
/// - SeeAlso: ``Endpoint``
/// - Note: 이 enum의 rawValue는 URLRequest의 httpMethod에 직접 사용됩니다.
enum HTTPMethod: String {

    /// GET 메서드 - 리소스 조회
    ///
    /// 서버로부터 데이터를 조회하는 데 사용됩니다.
    /// 서버 상태를 변경하지 않으며, 같은 요청을 여러 번 해도 동일한 결과를 반환합니다.
    ///
    /// ## 특징
    /// - 멱등성: O (같은 요청 반복 시 동일한 결과)
    /// - 안전성: O (서버 상태 변경 없음)
    /// - 캐싱: 가능
    /// - 요청 바디: 일반적으로 없음
    ///
    /// ## 사용 예시
    /// - 사용자 목록 조회
    /// - 프로필 정보 조회
    /// - 게시글 목록 조회
    /// - 검색 결과 조회
    ///
    /// ```swift
    /// // 유저 검색
    /// case searchUsers(query: String)
    /// // method: .get
    /// // queryItems: [URLQueryItem(name: "query", value: query)]
    ///
    /// // 내 프로필 조회
    /// case getMyProfile
    /// // method: .get
    /// ```
    case get = "GET"

    /// POST 메서드 - 리소스 생성 및 처리
    ///
    /// 새로운 리소스를 생성하거나 서버에서 데이터를 처리하는 데 사용됩니다.
    /// 같은 요청을 여러 번 하면 각각 새로운 리소스가 생성됩니다.
    ///
    /// ## 특징
    /// - 멱등성: X (요청마다 새 리소스 생성)
    /// - 안전성: X (서버 상태 변경)
    /// - 캐싱: 불가능
    /// - 요청 바디: 있음 (JSON, Form Data 등)
    ///
    /// ## 사용 예시
    /// - 회원가입
    /// - 로그인
    /// - 게시글 작성
    /// - 댓글 작성
    /// - 파일 업로드
    ///
    /// ```swift
    /// // 회원가입
    /// case signUp(email: String, password: String, nickname: String)
    /// // method: .post
    /// // parameters: ["email": email, "password": password, "nick": nickname]
    ///
    /// // 로그인
    /// case login(email: String, password: String)
    /// // method: .post
    /// // parameters: ["email": email, "password": password]
    /// ```
    case post = "POST"

    /// PUT 메서드 - 리소스 전체 업데이트
    ///
    /// 기존 리소스의 전체 내용을 업데이트하는 데 사용됩니다.
    /// 같은 요청을 여러 번 해도 결과가 동일합니다(멱등성).
    ///
    /// ## 특징
    /// - 멱등성: O (같은 요청 반복 시 동일한 결과)
    /// - 안전성: X (서버 상태 변경)
    /// - 캐싱: 불가능
    /// - 요청 바디: 있음 (전체 리소스 데이터)
    ///
    /// ## 사용 예시
    /// - 프로필 전체 수정
    /// - 게시글 전체 수정
    /// - 설정 업데이트
    ///
    /// ## PUT vs PATCH
    /// - PUT: 리소스 **전체** 교체
    /// - PATCH: 리소스 **일부** 수정
    ///
    /// ```swift
    /// // 프로필 수정
    /// case updateMyProfile(nick: String?, phoneNum: String?, birthDay: String?)
    /// // method: .put
    /// // parameters: 모든 필드 포함
    /// ```
    ///
    /// - Note: 이 프로젝트에서는 PATCH 대신 PUT을 사용합니다.
    case put = "PUT"

    /// DELETE 메서드 - 리소스 삭제
    ///
    /// 서버의 리소스를 삭제하는 데 사용됩니다.
    /// 같은 요청을 여러 번 해도 결과가 동일합니다(이미 삭제된 상태).
    ///
    /// ## 특징
    /// - 멱등성: O (이미 삭제된 리소스 재삭제 시 동일한 결과)
    /// - 안전성: X (서버 상태 변경)
    /// - 캐싱: 불가능
    /// - 요청 바디: 일반적으로 없음
    ///
    /// ## 사용 예시
    /// - 회원 탈퇴
    /// - 게시글 삭제
    /// - 댓글 삭제
    ///
    /// ```swift
    /// // 회원 탈퇴
    /// case withdraw
    /// // method: .delete
    ///
    /// // 게시글 삭제
    /// case deletePost(postId: String)
    /// // method: .delete
    /// // path: "/v1/posts/\(postId)"
    /// ```
    ///
    /// - Important: 삭제 작업은 되돌릴 수 없으므로 신중하게 사용해야 합니다.
    case delete = "DELETE"
}
