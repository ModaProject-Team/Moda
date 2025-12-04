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
    @Persisted var updatedAtDate: Date
    @Persisted var lastSyncedAt: String?

    @Persisted var participantNick: String?
    @Persisted var participantProfileImage: String?
    @Persisted var participantUserId: String?

    @Persisted var lastMessageContent: String?
    @Persisted var lastMessageCreatedAt: String?
    @Persisted var lastMessageCreatedAtDate: Date?
    @Persisted var lastMessageFilesJson: String?

    convenience init(
        roomId: String,
        updatedAt: String,
        updatedAtDate: Date,
        lastSyncedAt: String? = nil,
        participantNick: String? = nil,
        participantProfileImage: String? = nil,
        participantUserId: String? = nil,
        lastMessageContent: String? = nil,
        lastMessageCreatedAt: String? = nil,
        lastMessageCreatedAtDate: Date? = nil,
        lastMessageFilesJson: String? = nil
    ) {
        self.init()
        self.roomId = roomId
        self.updatedAt = updatedAt
        self.updatedAtDate = updatedAtDate
        self.lastSyncedAt = lastSyncedAt
        self.participantNick = participantNick
        self.participantProfileImage = participantProfileImage
        self.participantUserId = participantUserId
        self.lastMessageContent = lastMessageContent
        self.lastMessageCreatedAt = lastMessageCreatedAt
        self.lastMessageCreatedAtDate = lastMessageCreatedAtDate
        self.lastMessageFilesJson = lastMessageFilesJson
    }
}

extension ChatRoomObject {
    /// ChatRoomResponse로부터 생성
    /// - Parameters:
    ///   - response: 서버 응답 DTO
    ///   - currentUserId: 현재 사용자 ID (상대방 파악용)
    /// - Returns: ChatRoomObject 인스턴스
    static func from(response: ChatRoomResponse, currentUserId: String?) -> ChatRoomObject {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let updatedAtDate = formatter.date(from: response.updatedAt) ?? Date()

        let opponent = response.participants.first(where: { $0.userId != currentUserId }) ?? response.participants.first

        let lastMessageFilesJson: String?
        if let lastChat = response.lastChat {
            let filesData = try? JSONEncoder().encode(lastChat.files)
            lastMessageFilesJson = filesData.flatMap { String(data: $0, encoding: .utf8) }
        } else {
            lastMessageFilesJson = nil
        }

        return ChatRoomObject(
            roomId: response.roomId,
            updatedAt: response.updatedAt,
            updatedAtDate: updatedAtDate,
            participantNick: opponent?.nick,
            participantProfileImage: opponent?.profileImage,
            participantUserId: opponent?.userId,
            lastMessageContent: response.lastChat?.content,
            lastMessageCreatedAt: response.lastChat?.createdAt,
            lastMessageCreatedAtDate: response.lastChat.flatMap { formatter.date(from: $0.createdAt) },
            lastMessageFilesJson: lastMessageFilesJson
        )
    }

    /// 마지막 동기화 시간 업데이트
    /// - Parameter date: 동기화 시간
    func updateLastSynced(date: Date = Date()) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.lastSyncedAt = formatter.string(from: date)
    }
}
