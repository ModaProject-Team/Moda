//
//  WebViewState.swift
//  Moda
//
//  Created by Suji Jang on 12/08/24.
//

import Foundation

/// WebView 상태
enum WebViewStatus: Equatable {
    /// 초기 상태
    case idle

    /// 로딩 중
    case loading

    /// 로드 완료
    case ready

    /// 에러 발생
    case error(String)

    static func == (lhs: WebViewStatus, rhs: WebViewStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.loading, .loading),
             (.ready, .ready):
            return true
        case (.error(let lhsMessage), .error(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

