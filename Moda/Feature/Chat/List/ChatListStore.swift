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
    private let realmService: ChatRealmServiceProtocol

    private var myUserId: String?

    init(
        chatAPI: ChatAPIProtocol = ChatAPI.shared,
        userProfileAPI: UserProfileAPIProtocol = UserProfileAPI.shared,
        realmService: ChatRealmServiceProtocol = ChatRealmService.shared
    ) {
        self.chatAPI = chatAPI
        self.userProfileAPI = userProfileAPI
        self.realmService = realmService
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
            lastMessageTime: lastMessageTime
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

    private func mapFromObject(_ object: ChatRoomObject) -> ChatRoom {
        let lastMessageText: String
        let lastMessageTime: Date

        if let content = object.lastMessageContent, !content.isEmpty {
            lastMessageText = content
        } else if object.lastMessageFilesJson != nil {
            lastMessageText = "파일"
        } else {
            lastMessageText = ""
        }

        lastMessageTime = object.lastMessageCreatedAtDate ?? object.updatedAtDate

        return ChatRoom(
            id: object.roomId,
            participantName: object.participantNick ?? "알 수 없음",
            participantProfileImage: object.participantProfileImage,
            lastMessage: lastMessageText,
            lastMessageTime: lastMessageTime
        )
    }

    private func loadRooms() async {
        await setLoading(true)

        let localRooms = await realmService.getAllRooms()

        if !localRooms.isEmpty {
            await MainActor.run {
                self.state.chatRooms = localRooms.map(self.mapFromObject)
            }
        }

        do {
            try await ensureMyUserId()

            let response = try await chatAPI.getRooms()

            let roomObjects = response.data.map { ChatRoomObject.from(response: $0, currentUserId: self.myUserId) }
            try? await realmService.saveRooms(roomObjects)

            await applyRooms(response.data)
            await setLoading(false)
        } catch {
            if state.chatRooms.isEmpty {
                await MainActor.run {
                    self.state.errorMessage = (error as? NetworkError)?.localizedDescription ?? "채팅방을 불러오지 못했어요."
                    self.state.isLoading = false
                }
            } else {
                await setLoading(false)
            }
        }
    }
}
