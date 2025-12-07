//
//  AdMobError.swift
//  Moda
//
//  Created by 금가경 on 12/06/25.
//

import Foundation

/// AdMob 관련 에러 정의
enum AdMobError: LocalizedError {
    case notInitialized
    case loadFailed(message: String)
    case noInventory
    case networkError
    case invalidRequest

    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "AdMob이 초기화되지 않았습니다"
        case .loadFailed(let message):
            return message
        case .noInventory:
            return "사용 가능한 광고가 없습니다"
        case .networkError:
            return "광고 로드 중 네트워크 오류가 발생했습니다"
        case .invalidRequest:
            return "잘못된 광고 요청입니다"
        }
    }
}
