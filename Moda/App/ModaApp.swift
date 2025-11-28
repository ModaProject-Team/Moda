//
//  ModaApp.swift
//  Moda
//
//  Created by 금가경 on 11/6/25.
//

import SwiftUI
import KakaoSDKCommon
import KakaoSDKAuth

@main
struct ModaApp: App {
    @StateObject private var navigator = AppNavigator.shared

    init() {
        if Thread.isMainThread {
            initializeKakaoSDK()
            checkLoginStatus()
        } else {
            DispatchQueue.main.sync {
                initializeKakaoSDK()
                checkLoginStatus()
            }
        }
    }

    @MainActor
    private func initializeKakaoSDK() {
        let appKey = Bundle.main.object(forInfoDictionaryKey: "KakaoKey") as? String
        if let appKey, !appKey.isEmpty {
            KakaoSDK.initSDK(appKey: appKey)
        } else {
            assertionFailure("Kakao App Key is missing")
        }
    }

    @MainActor
    private func checkLoginStatus() {
        // 앱 시작 시 저장된 토큰이 있으면 자동 로그인
        if TokenManager.shared.isLoggedIn {
            AppNavigator.shared.isLoggedIn = true
        }
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $navigator.path) {
                Group {
                    if navigator.isLoggedIn {
                        MainTabView()
                    } else {
                        LoginView()
                    }
                }
                .navigationDestination(for: NavigationDestination.self) { destination in
                    destination.view()
                }
            }
            .environmentObject(navigator)
        }
    }
}
