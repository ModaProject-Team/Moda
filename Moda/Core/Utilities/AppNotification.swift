//
//  AppNotification.swift
//  Moda
//
//  Created by 금가경 on 11/30/24.
//

import Foundation

/// 앱 전역 Notification 이름 정의
///
/// NotificationCenter에서 사용할 커스텀 Notification 이름을 중앙에서 관리합니다.
/// Enum으로 구조화하여 타입 안정성을 보장하고 오타를 방지합니다.
enum AppNotification {
    // MARK: - Post (게시글 관련)

    /// 게시글 삭제 완료
    static let postDeleted = Notification.Name("com.moda.post.deleted")

    /// 게시글 좋아요 상태 변경
    static let postLikeUpdated = Notification.Name("com.moda.post.likeUpdated")

    /// 게시글 결제 완료
    static let postPaymentCompleted = Notification.Name("com.moda.post.paymentCompleted")

    /// 게시글 수정 완료
    static let postUpdated = Notification.Name("com.moda.post.updated")

    // MARK: - Comment (댓글 관련)

    /// 댓글 업데이트 (추가/수정/삭제)
    static let commentUpdated = Notification.Name("com.moda.comment.updated")

    // MARK: - Payment (결제 관련)

    /// 결제 응답 수신
    static let paymentResponse = Notification.Name("com.moda.payment.response")
}
