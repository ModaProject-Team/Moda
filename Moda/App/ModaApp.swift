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
    @Environment(\.scenePhase) private var scenePhase

    init() {
        if Thread.isMainThread {
            initializeKakaoSDK()
            checkLoginStatus()
            cleanupCacheOnStartup()
        } else {
            DispatchQueue.main.sync {
                initializeKakaoSDK()
                checkLoginStatus()
                cleanupCacheOnStartup()
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
        if TokenManager.shared.isLoggedIn {
            AppNavigator.shared.isLoggedIn = true
        }
    }

    @MainActor
    private func cleanupCacheOnStartup() {
        Task {
            await VideoCacheManager.shared.cleanupIfNeeded()
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
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .background {
                    Task {
                        await VideoCacheManager.shared.cleanupIfNeeded()
                    }
                }
            }
        }
    }
}
