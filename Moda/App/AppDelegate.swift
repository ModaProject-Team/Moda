//
//  AppDelegate.swift
//  Moda
//
//  Created by Suji Jang on 11/25/24.
//

import UIKit
import iamport_ios

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // iamport-ios에서 외부 앱(카드사 앱 등)으로부터 돌아온 URL 처리
        Iamport.shared.receivedURL(url)
        return true
    }
}
