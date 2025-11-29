//
//  ChatRoomObject.swift
//  Moda
//
//  Created by 금가경 on 11/29/25.
//

import Foundation
import RealmSwift

/// 채팅방 메타데이터 로컬 저장 모델
class ChatRoomObject: Object {
    @Persisted(primaryKey: true) var roomId: String
    @Persisted(indexed: true) var updatedAt: String
    @Persisted var lastSyncedAt: String?
    @Persisted var unreadCount: Int = 0

    convenience init(
        roomId: String,
        updatedAt: String,
        lastSyncedAt: String? = nil,
        unreadCount: Int = 0
    ) {
        self.init()
        self.roomId = roomId
        self.updatedAt = updatedAt
        self.lastSyncedAt = lastSyncedAt
        self.unreadCount = unreadCount
    }
}

extension ChatRoomObject {
    /// ChatRoomResponse로부터 업데이트
    /// - Parameter response: 서버 응답 DTO
    func update(from response: ChatRoomResponse) {
        self.updatedAt = response.updatedAt
    }

    /// 마지막 동기화 시간 업데이트
    /// - Parameter date: 동기화 시간
    func updateLastSynced(date: Date = Date()) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.lastSyncedAt = formatter.string(from: date)
    }

    /// 읽지 않은 메시지 수 증가
    func incrementUnreadCount() {
        self.unreadCount += 1
    }

    /// 읽지 않은 메시지 수 초기화
    func resetUnreadCount() {
        self.unreadCount = 0
    }
}
