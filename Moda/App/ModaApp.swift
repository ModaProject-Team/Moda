//
//  ModaApp.swift
//  Moda
//
//  Created by 금가경 on 11/6/25.
//

import Yolk
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
            setupCacheModifier()
            cleanupCacheOnStartup()
        } else {
            DispatchQueue.main.sync {
                initializeKakaoSDK()
                checkLoginStatus()
                setupCacheModifier()
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
    private func setupCacheModifier() {
        // Moda 프로젝트 전용 RequestModifier 설정
        let modifier = AnyModifier { request in
            var r = request
            r.setValue(NetworkConfig.sesacKey, forHTTPHeaderField: "SesacKey")
            r.setValue(NetworkConfig.productId, forHTTPHeaderField: "ProductId")
            r.setValue(TokenManager.shared.accessToken ?? "", forHTTPHeaderField: "Authorization")
            return r
        }

        Task {
            await CacheService.image.setModifier(modifier)
            await CacheService.video.setModifier(modifier)
        }
    }

    @MainActor
    private func cleanupCacheOnStartup() {
        Task {
            await CacheService.video.cleanupIfNeeded()
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
                        await CacheService.video.cleanupIfNeeded()
                    }
                }
            }
        }
    }
}
