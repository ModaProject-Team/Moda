//
//  AdMobManager.swift
//  Moda
//
//  Created by 금가경 on 12/06/25.
//

import Foundation
import GoogleMobileAds
import AppTrackingTransparency
import AdSupport

/// AdMob SDK 초기화 및 권한 관리
final class AdMobManager {
    static let shared = AdMobManager()

    private(set) var isInitialized = false
    private(set) var hasTrackingPermission = false

    private init() {}

    /// AdMob SDK 초기화 (앱 시작 시 호출)
    func initialize() async {
        await MainActor.run {
            MobileAds.shared.start { [weak self] _ in
                self?.isInitialized = true
                NotificationCenter.default.post(name: AppNotification.adMobInitialized, object: nil)
            }
        }
    }

    /// ATT 권한 요청 (iOS 14.5+)
    @MainActor
    func requestTrackingPermission() async {
        if #available(iOS 14.5, *) {
            let status = await ATTrackingManager.requestTrackingAuthorization()
            hasTrackingPermission = (status == .authorized)
        } else {
            hasTrackingPermission = true
        }
    }
}
