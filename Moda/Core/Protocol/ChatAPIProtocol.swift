//
//  ChatAPIProtocol.swift
//  Moda
//
//  Created by hyunMac on 11/24/25.
//

import Foundation

protocol ChatAPIProtocol {
    func getOrCreateRoom(opponentId: String) async throws -> ChatRoomResponse

    func getRooms() async throws -> ChatRoomListResponse

    func sendMessage(roomId: String, content: String?, files: [String]?) async throws -> ChatMessageResponse

    func getMessages(roomId: String, cursorDate: String?) async throws -> ChatHistoryResponse

    // NEW: 채팅 파일 업로드
    func uploadFiles(roomId: String, files: [FileData]) async throws -> ChatFileUploadResponse
}
