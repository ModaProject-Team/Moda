//
//  ChatRoomStore.swift
//  Moda
//
//  Created by 금가경 on 11/29/25.
//

import SwiftUI
import PhotosUI

final class ChatRoomStore: ObservableObject {
    @Published private(set) var state = ChatRoomState()

    private let roomId: String
    private let chatAPI: ChatAPIProtocol
    private let userProfileAPI: UserProfileAPIProtocol
    private let socketService: ChatSocketServiceProtocol
    private let realmService: ChatRealmServiceProtocol

    private var myUserId: String?
    private var bufferedMessages: [ChatMessageResponse] = []
    private var isSocketReady = false

    init(
        roomId: String,
        participantName: String,
        chatAPI: ChatAPIProtocol = ChatAPI.shared,
        userProfileAPI: UserProfileAPIProtocol = UserProfileAPI.shared,
        socketService: ChatSocketServiceProtocol = ChatSocketService(),
        realmService: ChatRealmServiceProtocol = ChatRealmService.shared
    ) {
        self.roomId = roomId
        self.chatAPI = chatAPI
        self.userProfileAPI = userProfileAPI
        self.socketService = socketService
        self.realmService = realmService
        self.state.participantName = participantName
        setupSocketCallbacks()
    }

    func send(_ intent: ChatRoomIntent) {
        switch intent {
        case .onAppear:
            Task { await loadAndConnect() }
        case .onDisappear:
            disconnectSocket()
        case .inputTextChanged(let text):
            state.inputText = text
        case .sendButtonTapped:
            Task { await sendCurrentMessage() }
        case .dismissError:
            state.errorMessage = nil

        case .attachmentButtonTapped:
            state.showAttachmentSheet = true

        case .pickImage:
            state.showAttachmentSheet = false
            state.showImagePicker = true

        case .attachmentSheetDismissed:
            state.showAttachmentSheet = false

        case .imagePicked(let data):
            state.pendingImageData = data
            state.pendingType = .image
            Task { @MainActor in
                state.showImagePicker = false
                try? await Task.sleep(nanoseconds: 200_000_000)
                state.showSendConfirmAlert = true
            }

        case .imagePickerDismissed:
            state.showImagePicker = false

        case .showSendConfirm:
            state.showSendConfirmAlert = true

        case .hideSendConfirm:
            state.showSendConfirmAlert = false

        case .confirmSend:
            Task { await sendPendingFileIfNeeded() }

        case .cancelSend:
            state.pendingImageData = nil
            state.pendingType = .none
            state.showSendConfirmAlert = false

        case .showImageViewer(let url):
            state.selectedImageURL = url
            state.showImageViewer = true

        case .hideImageViewer:
            state.showImageViewer = false
            state.selectedImageURL = nil
        }
    }

    private func setupSocketCallbacks() {
        socketService.onConnect = {
        }
        socketService.onDisconnect = {
        }
        socketService.onError = { [weak self] message in
            Task { @MainActor in
                self?.state.errorMessage = message
            }
        }
        socketService.onChat = { [weak self] dto in
            guard let self else { return }

            if self.isSocketReady {
                Task { await self.handleRealtimeMessage(dto) }
            } else {
                self.bufferedMessages.append(dto)
            }
        }
    }

    private func loadAndConnect() async {
        guard !state.isLoading else { return }
        await setLoading(true)
        defer { Task { await setLoading(false) } }

        do {
            try await ensureMyUserId()

            await loadLocalMessages()

            connectSocket()

            try await syncWithServer()

            await applyBufferedMessages()

            isSocketReady = true
        } catch {
            await setError(error)
        }
    }

    private func loadLocalMessages() async {
        let localMessages = realmService.getMessages(roomId: roomId, limit: 100)
        let mapped = localMessages.map { $0.toChatMessage(currentUserId: myUserId ?? "") }

        await MainActor.run {
            self.state.messages = mapped.sorted { $0.createdAt < $1.createdAt }
        }
    }

    private func syncWithServer() async throws {
        let lastMessage = realmService.getLastMessage(roomId: roomId)
        let cursorDate = lastMessage?.createdAt

        let history = try await chatAPI.getMessages(roomId: roomId, cursorDate: cursorDate)

        let messageObjects = history.data.map { ChatMessageObject.from(response: $0) }
        try realmService.saveMessages(messageObjects)

        let allLocalMessages = realmService.getMessages(roomId: roomId, limit: 100)
        let mapped = allLocalMessages.map { $0.toChatMessage(currentUserId: myUserId ?? "") }

        await MainActor.run {
            self.state.messages = mapped.sorted { $0.createdAt < $1.createdAt }
        }
    }

    private func applyBufferedMessages() async {
        for dto in bufferedMessages {
            await handleRealtimeMessage(dto)
        }
        bufferedMessages.removeAll()
    }

    private func handleRealtimeMessage(_ dto: ChatMessageResponse) async {
        let messageObject = ChatMessageObject.from(response: dto)

        do {
            try realmService.saveMessage(messageObject)

            let mapped = messageObject.toChatMessage(currentUserId: myUserId ?? "")
            await MainActor.run {
                if !self.state.messages.contains(where: { $0.id == mapped.id }) {
                    self.state.messages.append(mapped)
                }
            }
        } catch {
            print("❌ Failed to save realtime message: \(error)")
        }
    }

    private func connectSocket() {
        guard TokenManager.shared.accessToken != nil else {
            Task { @MainActor in
                self.state.errorMessage = "인증이 필요합니다."
            }
            return
        }
        socketService.connect(roomId: roomId)
    }

    private func disconnectSocket() {
        socketService.disconnect()
    }

    private func ensureMyUserId() async throws {
        if myUserId == nil {
            let me = try await userProfileAPI.getMyProfile()
            self.myUserId = me.userId
        }
    }

    private func sendCurrentMessage() async {
        let text = state.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        await MainActor.run { state.inputText = "" }

        do {
            try await ensureMyUserId()
            let sent = try await chatAPI.sendMessage(roomId: roomId, content: text, files: nil)

            let messageObject = ChatMessageObject.from(response: sent)
            try realmService.saveMessage(messageObject)

            let mapped = messageObject.toChatMessage(currentUserId: myUserId ?? "")
            await MainActor.run {
                if !self.state.messages.contains(where: { $0.id == mapped.id }) {
                    self.state.messages.append(mapped)
                }
            }
        } catch {
            await setError(error)
        }
    }

    private func sendPendingFileIfNeeded() async {
        await MainActor.run {
            state.showSendConfirmAlert = false
        }

        do {
            try await ensureMyUserId()

            switch state.pendingType {
            case .image:
                guard let data = state.pendingImageData else { return }
                let files: [FileData] = [FileData(data: data, type: .image)]
                let uploadResponse = try await chatAPI.uploadFiles(roomId: roomId, files: files)
                let sent = try await chatAPI.sendMessage(roomId: roomId, content: nil, files: uploadResponse.files)

                let messageObject = ChatMessageObject.from(response: sent)
                try realmService.saveMessage(messageObject)

                let mapped = messageObject.toChatMessage(currentUserId: myUserId ?? "")
                await MainActor.run {
                    if !self.state.messages.contains(where: { $0.id == mapped.id }) {
                        self.state.messages.append(mapped)
                    }
                    self.state.pendingImageData = nil
                    self.state.pendingType = .none
                }

            case .none:
                return
            }
        } catch {
            await setError(error)
        }
    }

    private func mapToViewModel(_ dto: ChatMessageResponse) -> ChatMessage {
        let created = parseISODate(dto.createdAt)
        let myId = myUserId ?? ""
        let isMine = (dto.sender.userId == myId)

        let attachment: ChatMessage.Attachment? = {
            guard let path = dto.files.first, !path.isEmpty else { return nil }
            let ext = (path as NSString).pathExtension.lowercased()
            if ["jpg", "jpeg", "png", "gif", "webp"].contains(ext) {
                let full = makeFullURL(from: path)
                return .image(full)
            } else {
                return nil
            }
        }()

        let text: String
        if let content = dto.content, !content.isEmpty {
            text = content
        } else {
            text = attachment == nil ? "" : "파일"
        }

        return ChatMessage(
            id: dto.chatId,
            content: text,
            senderId: dto.sender.userId,
            senderName: dto.sender.nick,
            senderProfileImage: dto.sender.profileImage,
            createdAt: created,
            isMine: isMine,
            attachment: attachment
        )
    }

    private func makeFullURL(from path: String) -> URL {
        let urlString = "\(NetworkConfig.baseURL)/v1\(path)"
        return URL(string: urlString) ?? URL(fileURLWithPath: "/")
    }

    private func parseISODate(_ string: String) -> Date {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return iso.date(from: string) ?? Date()
    }

    @MainActor
    private func setLoading(_ loading: Bool) {
        state.isLoading = loading
        if loading { state.errorMessage = nil }
    }

    @MainActor
    private func setError(_ error: Error) {
        if let net = error as? NetworkError {
            state.errorMessage = net.localizedDescription
        } else {
            state.errorMessage = error.localizedDescription
        }
    }
}
