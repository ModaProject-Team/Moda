//
//  ChatMessageObject.swift
//  Moda
//
//  Created by 금가경 on 11/29/25.
//

import Foundation
import RealmSwift

/// 채팅 메시지 로컬 저장 모델
class ChatMessageObject: Object {
    @Persisted(primaryKey: true) var chatId: String
    @Persisted(indexed: true) var roomId: String
    @Persisted(indexed: true) var createdAt: String
    @Persisted var createdAtDate: Date
    @Persisted var content: String?
    @Persisted var senderId: String
    @Persisted var senderNick: String
    @Persisted var senderProfileImage: String?
    @Persisted var filesJson: String?
    @Persisted var localStatus: String = "synced"

    convenience init(
        chatId: String,
        roomId: String,
        createdAt: String,
        createdAtDate: Date,
        content: String?,
        senderId: String,
        senderNick: String,
        senderProfileImage: String?,
        filesJson: String?,
        localStatus: String = "synced"
    ) {
        self.init()
        self.chatId = chatId
        self.roomId = roomId
        self.createdAt = createdAt
        self.createdAtDate = createdAtDate
        self.content = content
        self.senderId = senderId
        self.senderNick = senderNick
        self.senderProfileImage = senderProfileImage
        self.filesJson = filesJson
        self.localStatus = localStatus
    }
}

extension ChatMessageObject {
    /// LocalStatus 상태 정의
    enum LocalStatus: String {
        case synced = "synced"
        case sending = "sending"
        case failed = "failed"
    }

    /// ChatMessage (UI 모델)로 변환
    /// - Parameter currentUserId: 현재 로그인한 사용자 ID
    /// - Returns: UI에서 사용할 ChatMessage 인스턴스
    func toChatMessage(currentUserId: String) -> ChatMessage {
        var attachment: ChatMessage.Attachment?

        if let filesJson = filesJson,
           let filesData = filesJson.data(using: .utf8),
           let files = try? JSONDecoder().decode([String].self, from: filesData),
           let firstFile = files.first {
            let urlString = firstFile.hasPrefix("http") ? firstFile : "\(NetworkConfig.baseURL)/v1\(firstFile)"
            if let url = URL(string: urlString) {
                attachment = .image(url)
            }
        }

        let status = ChatMessage.LocalStatus(rawValue: localStatus) ?? .synced

        return ChatMessage(
            id: chatId,
            content: content ?? "",
            senderId: senderId,
            senderName: senderNick,
            senderProfileImage: senderProfileImage,
            createdAt: createdAtDate,
            isMine: senderId == currentUserId,
            attachment: attachment,
            localStatus: status
        )
    }

    /// ChatMessageResponse (DTO)로부터 생성
    /// - Parameter response: 서버 응답 DTO
    /// - Returns: ChatMessageObject 인스턴스
    static func from(response: ChatMessageResponse) -> ChatMessageObject {
        let filesJson = try? JSONEncoder().encode(response.files)
        let filesString = filesJson.flatMap { String(data: $0, encoding: .utf8) }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let createdAtDate = dateFormatter.date(from: response.createdAt) ?? Date()

        return ChatMessageObject(
            chatId: response.chatId,
            roomId: response.roomId,
            createdAt: response.createdAt,
            createdAtDate: createdAtDate,
            content: response.content,
            senderId: response.sender.userId,
            senderNick: response.sender.nick,
            senderProfileImage: response.sender.profileImage,
            filesJson: filesString,
            localStatus: "synced"
        )
    }
}
