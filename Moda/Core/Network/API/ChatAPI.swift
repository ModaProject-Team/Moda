//
//  ChatAPI.swift
//  Moda
//
//  Created by hyunMac on 11/24/25.
//

import Foundation

final class ChatAPI: ChatAPIProtocol {
    static let shared = ChatAPI()

    private let networkService: NetworkServiceProtocol

    private init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
    }

    func getOrCreateRoom(opponentId: String) async throws -> ChatRoomResponse {
        try await networkService.request(
            endpoint: ChatRouter.getOrCreateRoom(opponentId: opponentId),
            responseType: ChatRoomResponse.self
        )
    }

    func getRooms() async throws -> ChatRoomListResponse {
        try await networkService.request(
            endpoint: ChatRouter.getRooms,
            responseType: ChatRoomListResponse.self
        )
    }

    func sendMessage(roomId: String, content: String?, files: [String]?) async throws -> ChatMessageResponse {
        try await networkService.request(
            endpoint: ChatRouter.sendMessage(roomId: roomId, content: content, files: files),
            responseType: ChatMessageResponse.self
        )
    }

    func getMessages(roomId: String, cursorDate: String?) async throws -> ChatHistoryResponse {
        try await networkService.request(
            endpoint: ChatRouter.getMessages(roomId: roomId, cursorDate: cursorDate),
            responseType: ChatHistoryResponse.self
        )
    }
}
