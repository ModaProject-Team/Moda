//
//  NavigationDestination.swift
//  Moda
//
//  Created by 금가경 on 11/15/24.
//

import SwiftUI

/// 앱 내 모든 화면 목적지를 정의하는 열거형
///
/// `NavigationDestination`은 앱에서 이동 가능한 모든 화면을 enum으로 정의합니다.
/// `AppNavigator`와 함께 사용하여 type-safe한 화면 전환을 제공합니다.
///
/// ## 사용 예시
///
/// ```swift
/// struct SomeView: View {
///     @EnvironmentObject var navigator: AppNavigator
///
///     var body: some View {
///         VStack {
///             // 단일 화면 이동
///             Button("로그인") {
///                 navigator.push(.login)
///             }
///
///             Button("물건 올리기") {
///                 navigator.push(.productUpload)
///             }
///
///             // 뒤로가기
///             Button("뒤로") {
///                 navigator.pop()
///             }
///
///             // 루트로 이동
///             Button("홈으로") {
///                 navigator.popToRoot()
///             }
///         }
///     }
/// }
/// ```
///
/// ## 새 화면 추가 방법
///
/// 1. enum에 새 case 추가
/// 2. `view()` extension에 해당 View 매핑 추가
///
/// ```swift
/// // 1. Case 추가
/// case myNewScreen
///
/// // 2. View 매핑 추가
/// case .myNewScreen:
///     MyNewScreenView()
/// ```
enum NavigationDestination: Hashable {
    /// 로그인 화면
    case login

    /// 회원가입 화면
    case signUp

    /// 이메일 회원가입 화면
    case emailSignUp

    /// 홈 화면
    case home

    /// 프로필 화면
    case profile

    /// 설정 화면
    case settings

    /// 물건 올리기 화면
    case productUpload

    // MARK: FriendTab
    /// 친구 검색 화면
    case friendSearch

    /// 친구 추가화 면
    case friendAdd

    /// 프로필 디테일 화면
    case profileDetail
}

// MARK: - View Mapping
extension NavigationDestination {
    /// 각 destination에 해당하는 View를 반환합니다
    ///
    /// - Returns: destination에 매핑된 SwiftUI View
    @ViewBuilder
    func view() -> some View {
        switch self {
        case .login:
            LoginView()
        case .signUp:
            SignUpView()
        case .emailSignUp:
            EmailSignUpView()
        case .home:
            FeedView()
        case .profile:
            // TODO: ProfileView 구현 후 교체
            Text("Profile View")
        case .settings:
            // TODO: SettingsView 구현 후 교체
            Text("Settings View")
        case .productUpload:
            ProductUploadView()

        //MARK: FriendTab
        case .friendSearch:
            FriendSearchView()
        case .friendAdd:
            FriendAddView()
        case .profileDetail:
            ProfileDetailView()
        }

    }
}
