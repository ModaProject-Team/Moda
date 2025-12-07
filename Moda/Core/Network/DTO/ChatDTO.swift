//
//  ChatDTO.swift
//  Moda
//
//  Created by 금가경 on 11/17/24.
//

import Foundation

struct ChatRoomResponse: Decodable {
    let roomId: String
    let createdAt: String
    let updatedAt: String
    let participants: [ChatParticipant]
    let lastChat: ChatMessageResponse?

    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case createdAt
        case updatedAt
        case participants
        case lastChat
    }
}

struct ChatParticipant: Decodable {
    let userId: String
    let nick: String
    let profileImage: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nick
        case profileImage
    }
}

struct ChatMessageResponse: Decodable {
    let chatId: String
    let roomId: String
    let content: String?
    let createdAt: String
    let sender: ChatParticipant
    let files: [String]

    enum CodingKeys: String, CodingKey {
        case chatId = "chat_id"
        case roomId = "room_id"
        case content
        case createdAt
        case sender
        case files
    }
}

struct ChatRoomListResponse: Decodable {
    let data: [ChatRoomResponse]
}

struct ChatHistoryResponse: Decodable {
    let data: [ChatMessageResponse]
}

struct ChatFileUploadResponse: Decodable {
    let files: [String]
}

// MARK: - Chat Helper Types

struct OptimisticChatMessage {
    let realmObject: ChatMessageObject
    let chatMessage: ChatMessage
}
