//
//  AdMobBannerView.swift
//  Moda
//
//  Created by 금가경 on 12/06/25.
//

import SwiftUI
import GoogleMobileAds

/// AdMob 배너 광고를 표시하는 SwiftUI View
struct AdMobBannerView: UIViewRepresentable {
    let adUnitID: String
    let onAdLoaded: () -> Void
    let onAdFailedToLoad: (AdMobError) -> Void

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: adSizeFor(cgSize: CGSize(width: 320, height: 110)))
        bannerView.adUnitID = adUnitID
        bannerView.delegate = context.coordinator

        return bannerView
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }

        uiView.rootViewController = rootViewController
        uiView.load(Request())
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onAdLoaded: onAdLoaded, onAdFailedToLoad: onAdFailedToLoad)
    }

    class Coordinator: NSObject, BannerViewDelegate {
        let onAdLoaded: () -> Void
        let onAdFailedToLoad: (AdMobError) -> Void

        init(onAdLoaded: @escaping () -> Void, onAdFailedToLoad: @escaping (AdMobError) -> Void) {
            self.onAdLoaded = onAdLoaded
            self.onAdFailedToLoad = onAdFailedToLoad
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            onAdLoaded()
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            let adError: AdMobError
            if let gadError = error as? NSError {
                switch gadError.code {
                case 2:
                    adError = .networkError
                case 3:
                    adError = .noInventory
                default:
                    adError = .loadFailed(message: error.localizedDescription)
                }
            } else {
                adError = .loadFailed(message: error.localizedDescription)
            }
            onAdFailedToLoad(adError)
        }
    }
}
