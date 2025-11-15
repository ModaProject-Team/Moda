//
//  AppNavigator.swift
//  Moda
//
//  Created by 금가경 on 11/15/24.
//

import SwiftUI

/// 앱 전체 네비게이션을 관리하는 중앙 집중식 네비게이터
///
/// `AppNavigator`는 SwiftUI의 `NavigationPath`를 사용하여
/// 앱의 모든 화면 전환을 체계적으로 관리합니다.
///
/// ## 주요 기능
///
/// - **Type-safe 네비게이션**: `NavigationDestination` enum 사용
/// - **프로그래밍 방식 제어**: 코드로 화면 전환 제어
/// - **딥링크 지원**: URL 기반 화면 이동
/// - **스택 관리**: push, pop, popToRoot
///
/// ## 사용 예시
///
/// ```swift
/// @EnvironmentObject var navigator: AppNavigator
///
/// // 화면 이동
/// navigator.push(.profile(userId: "123"))
///
/// // 뒤로 가기
/// navigator.pop()
///
/// // 루트로 이동
/// navigator.popToRoot()
///
/// // 여러 화면 연속 이동
/// navigator.push([.home, .settings])
/// ```
///
/// ## Environment 주입
///
/// ```swift
/// @main
/// struct ModaApp: App {
///     @StateObject private var navigator = AppNavigator()
///
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///                 .environmentObject(navigator)
///         }
///     }
/// }
/// ```
final class AppNavigator: ObservableObject {

    /// 네비게이션 스택
    ///
    /// SwiftUI의 `NavigationPath`를 사용하여 화면 스택을 관리합니다.
    /// Published로 선언되어 스택 변경 시 자동으로 UI가 업데이트됩니다.
    @Published var path = NavigationPath()

    /// 싱글톤 인스턴스
    ///
    /// 앱 전역에서 사용되는 단일 `AppNavigator` 인스턴스입니다.
    static let shared = AppNavigator()

    /// AppNavigator 초기화
    private init() {}

    // MARK: - Navigation Methods

    /// 새로운 화면으로 이동합니다
    ///
    /// - Parameter destination: 이동할 화면
    ///
    /// ## Example
    ///
    /// ```swift
    /// navigator.push(.profile(userId: "123"))
    /// ```
    func push(_ destination: NavigationDestination) {
        path.append(destination)
    }

    /// 여러 화면을 순차적으로 이동합니다
    ///
    /// - Parameter destinations: 이동할 화면 배열
    ///
    /// ## Example
    ///
    /// ```swift
    /// navigator.push([.home, .settings])
    /// ```
    func push(_ destinations: [NavigationDestination]) {
        destinations.forEach { path.append($0) }
    }

    /// 이전 화면으로 돌아갑니다
    ///
    /// 네비게이션 스택에서 마지막 화면을 제거합니다.
    /// 스택이 비어있으면 아무 동작도 하지 않습니다.
    ///
    /// ## Example
    ///
    /// ```swift
    /// navigator.pop()
    /// ```
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    /// 지정된 개수만큼 뒤로 이동합니다
    ///
    /// - Parameter count: 제거할 화면 개수
    ///
    /// ## Example
    ///
    /// ```swift
    /// navigator.pop(count: 2)  // 2개 화면 뒤로
    /// ```
    func pop(count: Int) {
        guard count > 0, !path.isEmpty else { return }
        let removableCount = min(count, path.count)
        path.removeLast(removableCount)
    }

    /// 루트 화면으로 돌아갑니다
    ///
    /// 네비게이션 스택을 모두 비워 첫 화면으로 이동합니다.
    ///
    /// ## Example
    ///
    /// ```swift
    /// navigator.popToRoot()
    /// ```
    func popToRoot() {
        path.removeLast(path.count)
    }

    // MARK: - Utility

    /// 현재 네비게이션 스택의 깊이를 반환합니다
    var depth: Int {
        return path.count
    }

    /// 네비게이션 스택이 비어있는지 확인합니다
    var isEmpty: Bool {
        return path.isEmpty
    }
}
