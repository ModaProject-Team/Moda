//
//  ChatListStore.swift
//  Moda
//
//  Created by 금가경 on 11/29/25.
//

import SwiftUI

final class ChatListStore: ObservableObject {
    @Published private(set) var state = ChatListState()

    private let chatAPI: ChatAPIProtocol
    private let userProfileAPI: UserProfileAPIProtocol

    private var myUserId: String?

    init(
        chatAPI: ChatAPIProtocol = ChatAPI.shared,
        userProfileAPI: UserProfileAPIProtocol = UserProfileAPI.shared
    ) {
        self.chatAPI = chatAPI
        self.userProfileAPI = userProfileAPI
    }

    func send(_ intent: ChatListIntent) {
        switch intent {
        case .chatRoomTapped:
            break
        case .loadRooms, .refresh:
            Task { await loadRooms() }
        }
    }

    @MainActor
    private func setLoading(_ loading: Bool) {
        state.isLoading = loading
        if loading {
            state.errorMessage = nil
        }
    }

    private func parseISODate(_ string: String) -> Date {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return iso.date(from: string) ?? Date()
    }

    private func mapToViewModel(_ dto: ChatRoomResponse) -> ChatRoom {
        let opponent: ChatParticipant?
        if let myId = myUserId {
            opponent = dto.participants.first(where: { $0.userId != myId }) ?? dto.participants.first
        } else {
            opponent = dto.participants.first
        }

        let lastMessageText: String
        let lastMessageTime: Date
        if let last = dto.lastChat {
            if let content = last.content, !content.isEmpty {
                lastMessageText = content
            } else {
                lastMessageText = last.files.isEmpty ? "" : "파일"
            }
            lastMessageTime = parseISODate(last.createdAt)
        } else {
            lastMessageText = ""
            lastMessageTime = parseISODate(dto.updatedAt)
        }

        return ChatRoom(
            id: dto.roomId,
            participantName: opponent?.nick ?? "알 수 없음",
            participantProfileImage: opponent?.profileImage,
            lastMessage: lastMessageText,
            lastMessageTime: lastMessageTime,
            unreadCount: 0
        )
    }

    @MainActor
    private func applyRooms(_ rooms: [ChatRoomResponse]) {
        self.state.chatRooms = rooms.map(mapToViewModel)
    }

    private func ensureMyUserId() async throws {
        if myUserId == nil {
            let me = try await userProfileAPI.getMyProfile()
            self.myUserId = me.userId
        }
    }

    private func loadRooms() async {
        await setLoading(true)
        do {
            try await ensureMyUserId()
            let response = try await chatAPI.getRooms()
            await applyRooms(response.data)
            await setLoading(false)
        } catch {
            await MainActor.run {
                self.state.errorMessage = (error as? NetworkError)?.localizedDescription ?? "채팅방을 불러오지 못했어요."
                self.state.isLoading = false
            }
        }
    }
}
