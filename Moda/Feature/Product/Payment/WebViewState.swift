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

    /// 타임아웃
    case timeout

    /// 에러 발생
    case error(String)

    static func == (lhs: WebViewStatus, rhs: WebViewStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.loading, .loading),
             (.ready, .ready),
             (.timeout, .timeout):
            return true
        case (.error(let lhsMessage), .error(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

/// WebView 설정
struct WebViewConfig {
    /// 타임아웃 시간 (초)
    static let timeout: TimeInterval = 30.0

    /// JavaScript 실행 타임아웃 (초)
    static let scriptTimeout: TimeInterval = 5.0

    /// 로딩 인디케이터 표시 딜레이 (초)
    static let loadingDelay: TimeInterval = 0.3
}
