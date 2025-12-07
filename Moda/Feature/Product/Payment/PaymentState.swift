//
//  PaymentState.swift
//  Moda
//
//  Created by Suji Jang on 12/08/24.
//

import Foundation

/// 결제 프로세스의 전체 상태
enum PaymentStatus: Equatable {
    /// 초기 상태 (결제 대기)
    case idle

    /// 상품 정보 검증 중
    case validatingProduct

    /// 결제 진행 중 (포트원 WebView)
    case processing

    /// 서버 검증 중
    case validatingPayment

    /// 재시도 중
    case retrying(attempt: Int, reason: RetryReason)

    /// 완료
    case completed

    /// 실패
    case failed(PaymentError)

    /// 진행 중인지 여부
    var isInProgress: Bool {
        switch self {
        case .idle, .completed, .failed:
            return false
        default:
            return true
        }
    }
}

/// 재시도 사유
enum RetryReason: Equatable {
    /// 네트워크 오류
    case networkError

    /// 서버 오류
    case serverError

    /// 타임아웃
    case timeout
}

/// 결제 에러 타입
enum PaymentError: Equatable {
    /// 상품이 이미 판매됨
    case productSoldOut

    /// 가격이 변경됨
    case priceChanged

    /// 상품 정보 조회 실패
    case productNotFound

    /// 네트워크 연결 없음
    case noNetwork

    /// 서버 검증 실패
    case validationFailed(message: String)

    /// 금액 위변조 감지
    case securityViolation

    /// 결제 취소 (사용자)
    case userCancelled

    /// 결제 응답 없음
    case noResponse

    /// 재시도 횟수 초과
    case maxRetriesExceeded

    /// 알 수 없는 오류
    case unknown(String)

    /// 사용자에게 표시할 메시지
    var userMessage: String {
        switch self {
        case .productSoldOut:
            return "이미 판매 완료된 상품입니다.\n다른 상품을 확인해주세요."

        case .priceChanged:
            return "상품 금액이 변경되었습니다.\n페이지를 새로고침 후 다시 시도해주세요."

        case .productNotFound:
            return "상품 정보를 확인할 수 없습니다.\n잠시 후 다시 시도해주세요."

        case .noNetwork:
            return "네트워크 연결을 확인해주세요."

        case .validationFailed(let message):
            return "결제 검증에 실패했습니다.\n\(message)\n\n결제는 자동으로 취소되며 환불됩니다."

        case .securityViolation:
            return "결제 금액 검증에 실패했습니다.\n\n보안상의 이유로 결제가 차단되었습니다.\n결제는 자동으로 취소되며 환불됩니다.\n\n문제가 지속되면 고객센터로 문의해주세요."

        case .userCancelled:
            return "결제가 취소되었습니다."

        case .noResponse:
            return "결제 응답을 받지 못했습니다.\n잠시 후 다시 시도해주세요."

        case .maxRetriesExceeded:
            return "결제 처리 중 오류가 계속 발생했습니다.\n잠시 후 다시 시도해주세요."

        case .unknown(let message):
            return "결제 중 오류가 발생했습니다.\n\(message)"
        }
    }

    /// 재시도 가능 여부
    var isRetryable: Bool {
        switch self {
        case .noNetwork, .productNotFound:
            return true
        case .validationFailed:
            return true
        case .productSoldOut, .priceChanged, .securityViolation, .userCancelled, .noResponse, .maxRetriesExceeded:
            return false
        case .unknown:
            return false
        }
    }
}

/// 결제 재시도 설정
struct PaymentRetryConfig {
    /// 최대 재시도 횟수
    static let maxRetries = 3

    /// 재시도 간격 (초) - 지수 백오프
    static func retryDelay(for attempt: Int) -> TimeInterval {
        return min(pow(2.0, Double(attempt)), 10.0) // 최대 10초
    }

    /// 네트워크 복구 대기 시간 (초)
    static let networkRecoveryDelay: TimeInterval = 2.0
}
