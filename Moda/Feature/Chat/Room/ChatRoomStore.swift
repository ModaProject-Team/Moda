//
//  ChatRoomStore.swift
//  Moda
//
//  Created by 금가경 on 11/29/25.
//

import SwiftUI
import PhotosUI
import Combine

final class ChatRoomStore: ObservableObject {
    @Published private(set) var state = ChatRoomState()

    private let roomId: String
    private let chatAPI: ChatAPIProtocol
    private let userProfileAPI: UserProfileAPIProtocol
    private let socketService: ChatSocketServiceProtocol
    private let realmService: ChatRealmServiceProtocol
    private let networkMonitor: NetworkMonitor

    private var myUserId: String?
    private var bufferedMessages: [ChatMessageResponse] = []
    private var isSocketReady = false
    private var cancellables = Set<AnyCancellable>()
    private var networkDebounceTask: Task<Void, Never>?

    init(
        roomId: String,
        participantName: String,
        chatAPI: ChatAPIProtocol = ChatAPI.shared,
        userProfileAPI: UserProfileAPIProtocol = UserProfileAPI.shared,
        socketService: ChatSocketServiceProtocol = ChatSocketService(),
        realmService: ChatRealmServiceProtocol = ChatRealmService.shared,
        networkMonitor: NetworkMonitor = NetworkMonitor.shared
    ) {
        self.roomId = roomId
        self.chatAPI = chatAPI
        self.userProfileAPI = userProfileAPI
        self.socketService = socketService
        self.realmService = realmService
        self.networkMonitor = networkMonitor
        self.state.participantName = participantName
        setupSocketCallbacks()
        setupNetworkMonitoring()
    }

    func send(_ intent: ChatRoomIntent) {
        switch intent {
        case .onAppear:
            networkMonitor.startMonitoring()
            Task { await loadAndConnect() }
        case .onDisappear:
            networkMonitor.stopMonitoring()
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

        case .retryMessage(let chatId):
            Task { await retryFailedMessage(chatId: chatId) }

        case .deleteMessage(let chatId):
            Task { await deleteFailedMessage(chatId: chatId) }

        case .retryConnection:
            Task { await retryConnection() }

        case .loadMoreMessages:
            Task { await loadMoreMessages() }
        }
    }

    private func setupSocketCallbacks() {
        socketService.onConnect = { [weak self] in
            Task { @MainActor in
                self?.state.isNetworkError = false
            }
        }
        socketService.onDisconnect = { [weak self] in
            Task { @MainActor in
                self?.state.isNetworkError = true
            }
        }
        socketService.onError = { [weak self] message in
            Task { @MainActor in
                self?.state.isNetworkError = true
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

    private func setupNetworkMonitoring() {
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                guard let self = self else { return }

                if isConnected {
                    self.networkDebounceTask?.cancel()
                    self.networkDebounceTask = nil

                    if self.state.isNetworkError {
                        self.state.isNetworkError = false
                        Task {
                            try? await self.reconnectIfNeeded()
                        }
                    }
                } else {
                    self.networkDebounceTask?.cancel()
                    self.networkDebounceTask = Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        if !Task.isCancelled {
                            self.state.isNetworkError = true
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func reconnectIfNeeded() async throws {
        disconnectSocket()
        try? await Task.sleep(nanoseconds: 500_000_000)
        connectSocket()
        try await syncWithServer()
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
        let userId = myUserId ?? ""
        let roomIdCopy = roomId

        let messages = await realmService.getMessages(roomId: roomIdCopy, limit: 100, currentUserId: userId)

        for message in messages where message.localStatus == .sending {
            try? await realmService.updateMessageStatus(chatId: message.id, status: "failed")
        }

        let localMessages = messages.map { message in
            if message.localStatus == .sending {
                return ChatMessage(
                    id: message.id,
                    content: message.content,
                    senderId: message.senderId,
                    senderName: message.senderName,
                    senderProfileImage: message.senderProfileImage,
                    createdAt: message.createdAt,
                    isMine: message.isMine,
                    attachment: message.attachment,
                    localStatus: .failed
                )
            }
            return message
        }

        await MainActor.run {
            self.state.messages = localMessages.sorted { $0.createdAt < $1.createdAt }
        }
    }

    private func syncWithServer() async throws {
        let userId = myUserId ?? ""
        let roomIdCopy = roomId

        let lastMessage = await realmService.getLastMessage(roomId: roomIdCopy)
        let cursorDate = lastMessage?.createdAt

        let history = try await chatAPI.getMessages(roomId: roomId, cursorDate: cursorDate)

        let messageObjects = history.data.map { ChatMessageObject.from(response: $0) }
        try? await realmService.saveMessages(messageObjects)

        let allLocalMessages = await realmService.getMessages(roomId: roomIdCopy, limit: 100, currentUserId: userId)

        await MainActor.run {
            self.state.messages = allLocalMessages.sorted { $0.createdAt < $1.createdAt }
        }
    }

    private func applyBufferedMessages() async {
        for dto in bufferedMessages {
            await handleRealtimeMessage(dto)
        }
        bufferedMessages.removeAll()
    }

    private func handleRealtimeMessage(_ dto: ChatMessageResponse) async {
        let userId = myUserId ?? ""

        let messageObject = ChatMessageObject.from(response: dto)
        try? await realmService.saveMessage(messageObject)

        let mapped = ChatMessage(
            id: dto.chatId,
            content: dto.content ?? "",
            senderId: dto.sender.userId,
            senderName: dto.sender.nick,
            senderProfileImage: dto.sender.profileImage,
            createdAt: parseISO(dto.createdAt),
            isMine: dto.sender.userId == userId,
            attachment: parseAttachment(dto.files),
            localStatus: .synced
        )

        await MainActor.run {
            if !self.state.messages.contains(where: { $0.id == mapped.id }) {
                self.state.messages.append(mapped)
            }
        }
    }

    private func parseISO(_ string: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: string) ?? Date()
    }

    private func parseAttachment(_ files: [String]) -> ChatMessage.Attachment? {
        guard let firstFile = files.first, !firstFile.isEmpty else { return nil }
        let urlString = "\(NetworkConfig.baseURL)/v1\(firstFile)"
        guard let url = URL(string: urlString) else { return nil }
        return .image(url)
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

    private func retryConnection() async {
        await MainActor.run {
            state.isNetworkError = false
        }

        disconnectSocket()

        try? await Task.sleep(nanoseconds: 500_000_000)

        connectSocket()

        do {
            try await syncWithServer()
        } catch {
            await MainActor.run {
                state.isNetworkError = true
            }
        }
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

        let tempId = "temp-\(UUID().uuidString)"

        try? await ensureMyUserId()
        let userId = myUserId ?? ""
        let me = try? await userProfileAPI.getMyProfile()

        let roomIdCopy = roomId

        let optimisticMessage = ChatMessageObject(
            chatId: tempId,
            roomId: roomIdCopy,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            createdAtDate: Date(),
            content: text,
            senderId: me?.userId ?? userId,
            senderNick: me?.nick ?? "",
            senderProfileImage: me?.profileImage,
            filesJson: nil,
            localStatus: "sending"
        )

        try? await realmService.saveMessage(optimisticMessage)

        let optimistic = ChatMessage(
            id: tempId,
            content: text,
            senderId: me?.userId ?? userId,
            senderName: me?.nick ?? "",
            senderProfileImage: me?.profileImage,
            createdAt: Date(),
            isMine: true,
            attachment: nil,
            localStatus: .sending
        )

        await MainActor.run {
            self.state.messages.append(optimistic)
        }

        do {
            let sent = try await sendMessageWithRetry(content: text, files: nil, retryCount: 3)

            let actualMessage = ChatMessageObject.from(response: sent)
            try? await realmService.saveMessage(actualMessage)

            let mapped = ChatMessage(
                id: sent.chatId,
                content: sent.content ?? "",
                senderId: sent.sender.userId,
                senderName: sent.sender.nick,
                senderProfileImage: sent.sender.profileImage,
                createdAt: parseISO(sent.createdAt),
                isMine: sent.sender.userId == userId,
                attachment: parseAttachment(sent.files),
                localStatus: .synced
            )

            await MainActor.run {
                if let index = self.state.messages.firstIndex(where: { $0.id == tempId }) {
                    self.state.messages.remove(at: index)
                }
                if !self.state.messages.contains(where: { $0.id == mapped.id }) {
                    self.state.messages.append(mapped)
                }
            }
        } catch {
            try? await realmService.updateMessageStatus(chatId: tempId, status: "failed")

            await MainActor.run {
                if let index = self.state.messages.firstIndex(where: { $0.id == tempId }) {
                    let failedMessage = self.state.messages[index]
                    self.state.messages[index] = ChatMessage(
                        id: failedMessage.id,
                        content: failedMessage.content,
                        senderId: failedMessage.senderId,
                        senderName: failedMessage.senderName,
                        senderProfileImage: failedMessage.senderProfileImage,
                        createdAt: failedMessage.createdAt,
                        isMine: failedMessage.isMine,
                        attachment: failedMessage.attachment,
                        localStatus: .failed
                    )
                }
            }
        }
    }

    /// 지수 백오프를 적용한 메시지 재전송
    /// - Parameters:
    ///   - content: 메시지 내용
    ///   - files: 첨부 파일 경로 배열
    ///   - retryCount: 최대 재시도 횟수
    /// - Returns: 전송된 메시지 응답
    /// - Throws: 모든 재시도 실패 시 마지막 에러
    private func sendMessageWithRetry(content: String?, files: [String]?, retryCount: Int) async throws -> ChatMessageResponse {
        var lastError: Error?
        let baseDelay: UInt64 = 500_000_000 // 0.5초
        let maxDelay: UInt64 = 8_000_000_000 // 8초

        for attempt in 0..<retryCount {
            do {
                return try await chatAPI.sendMessage(roomId: roomId, content: content, files: files)
            } catch {
                lastError = error
                if attempt < retryCount - 1 {
                    // 지수 백오프: 0.5초 * 2^attempt (최대 8초)
                    let exponentialDelay = baseDelay * UInt64(pow(2.0, Double(attempt)))
                    let delay = min(exponentialDelay, maxDelay)
                    try? await Task.sleep(nanoseconds: delay)
                }
            }
        }

        throw lastError ?? NetworkError.networkFailure
    }

    /// 실패한 메시지 삭제
    /// - Parameter chatId: 삭제할 메시지 ID
    private func deleteFailedMessage(chatId: String) async {
        await MainActor.run {
            self.state.messages.removeAll(where: { $0.id == chatId })
        }

        // Realm에서도 삭제
        try? await realmService.deleteMessage(chatId: chatId)
    }

    private func retryFailedMessage(chatId: String) async {
        let message = await realmService.getMessage(chatId: chatId)

        guard let message = message else { return }
        guard message.localStatus == .failed else { return }

        let content = message.content
        let attachment = message.attachment

        // 기존 실패 메시지 삭제
        await MainActor.run {
            self.state.messages.removeAll(where: { $0.id == chatId })
        }

        // 새로운 tempId로 재전송 메시지 생성 (맨 아래 추가, 새로운 타임스탬프)
        let newTempId = "temp-\(UUID().uuidString)"
        let now = Date()

        try? await ensureMyUserId()
        let userId = myUserId ?? ""
        let me = try? await userProfileAPI.getMyProfile()
        let roomIdCopy = roomId

        let optimisticMessage = ChatMessageObject(
            chatId: newTempId,
            roomId: roomIdCopy,
            createdAt: ISO8601DateFormatter().string(from: now),
            createdAtDate: now,
            content: content.isEmpty ? nil : content,
            senderId: me?.userId ?? userId,
            senderNick: me?.nick ?? "",
            senderProfileImage: me?.profileImage,
            filesJson: nil,
            localStatus: "sending"
        )

        try? await realmService.saveMessage(optimisticMessage)

        let optimistic = ChatMessage(
            id: newTempId,
            content: content,
            senderId: me?.userId ?? userId,
            senderName: me?.nick ?? "",
            senderProfileImage: me?.profileImage,
            createdAt: now,
            isMine: true,
            attachment: attachment,
            localStatus: .sending
        )

        await MainActor.run {
            self.state.messages.append(optimistic)
        }

        do {
            let sent = try await sendMessageWithRetry(
                content: content.isEmpty ? nil : content,
                files: nil,
                retryCount: 3
            )

            let actualMessage = ChatMessageObject.from(response: sent)
            try? await realmService.saveMessage(actualMessage)

            let mapped = ChatMessage(
                id: sent.chatId,
                content: sent.content ?? "",
                senderId: sent.sender.userId,
                senderName: sent.sender.nick,
                senderProfileImage: sent.sender.profileImage,
                createdAt: parseISO(sent.createdAt),
                isMine: sent.sender.userId == userId,
                attachment: parseAttachment(sent.files),
                localStatus: .synced
            )

            await MainActor.run {
                // tempId 메시지 삭제하고 실제 메시지 추가
                self.state.messages.removeAll(where: { $0.id == newTempId })
                if !self.state.messages.contains(where: { $0.id == mapped.id }) {
                    self.state.messages.append(mapped)
                }
            }
        } catch {
            try? await realmService.updateMessageStatus(chatId: newTempId, status: "failed")

            // 재전송 실패 시 failed 상태로 변경
            await MainActor.run {
                if let index = self.state.messages.firstIndex(where: { $0.id == newTempId }) {
                    self.state.messages[index] = ChatMessage(
                        id: newTempId,
                        content: content,
                        senderId: optimistic.senderId,
                        senderName: optimistic.senderName,
                        senderProfileImage: optimistic.senderProfileImage,
                        createdAt: now,
                        isMine: true,
                        attachment: attachment,
                        localStatus: .failed
                    )
                }
            }
        }
    }

    private func sendPendingFileIfNeeded() async {
        await MainActor.run {
            state.showSendConfirmAlert = false
        }

        let tempId = "temp-\(UUID().uuidString)"

        switch state.pendingType {
        case .image:
            guard let data = state.pendingImageData else { return }

            try? await ensureMyUserId()
            let userId = myUserId ?? ""
            let me = try? await userProfileAPI.getMyProfile()
            let roomIdCopy = roomId

            let optimisticMessage = ChatMessageObject(
                chatId: tempId,
                roomId: roomIdCopy,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                createdAtDate: Date(),
                content: nil,
                senderId: me?.userId ?? userId,
                senderNick: me?.nick ?? "",
                senderProfileImage: me?.profileImage,
                filesJson: nil,
                localStatus: "sending"
            )

            try? await realmService.saveMessage(optimisticMessage)

            let optimistic = ChatMessage(
                id: tempId,
                content: "",
                senderId: me?.userId ?? userId,
                senderName: me?.nick ?? "",
                senderProfileImage: me?.profileImage,
                createdAt: Date(),
                isMine: true,
                attachment: nil,
                localStatus: .sending
            )

            await MainActor.run {
                self.state.messages.append(optimistic)
            }

            do {
                let files: [FileData] = [FileData(data: data, type: .image)]
                let uploadResponse = try await chatAPI.uploadFiles(roomId: roomId, files: files)
                let sent = try await sendMessageWithRetry(content: nil, files: uploadResponse.files, retryCount: 3)

                let messageObject = ChatMessageObject.from(response: sent)
                try? await realmService.saveMessage(messageObject)

                let mapped = ChatMessage(
                    id: sent.chatId,
                    content: sent.content ?? "",
                    senderId: sent.sender.userId,
                    senderName: sent.sender.nick,
                    senderProfileImage: sent.sender.profileImage,
                    createdAt: parseISO(sent.createdAt),
                    isMine: sent.sender.userId == userId,
                    attachment: parseAttachment(sent.files),
                    localStatus: .synced
                )

                await MainActor.run {
                    if let index = self.state.messages.firstIndex(where: { $0.id == tempId }) {
                        self.state.messages.remove(at: index)
                    }
                    if !self.state.messages.contains(where: { $0.id == mapped.id }) {
                        self.state.messages.append(mapped)
                    }
                    self.state.pendingImageData = nil
                    self.state.pendingType = .none
                }
            } catch {
                try? await realmService.updateMessageStatus(chatId: tempId, status: "failed")

                await MainActor.run {
                    if let index = self.state.messages.firstIndex(where: { $0.id == tempId }) {
                        let failedMessage = self.state.messages[index]
                        self.state.messages[index] = ChatMessage(
                            id: failedMessage.id,
                            content: failedMessage.content,
                            senderId: failedMessage.senderId,
                            senderName: failedMessage.senderName,
                            senderProfileImage: failedMessage.senderProfileImage,
                            createdAt: failedMessage.createdAt,
                            isMine: failedMessage.isMine,
                            attachment: failedMessage.attachment,
                            localStatus: .failed
                        )
                    }
                    self.state.pendingImageData = nil
                    self.state.pendingType = .none
                }
            }

        case .none:
            return
        }
    }


    private func loadMoreMessages() async {
        guard !state.isLoadingMore else { return }
        guard state.hasMoreMessages else { return }
        guard let oldestMessage = state.messages.first else { return }

        await MainActor.run {
            state.isLoadingMore = true
        }

        let userId = myUserId ?? ""
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let cursorDate = formatter.string(from: oldestMessage.createdAt)

        do {
            let history = try await chatAPI.getMessages(roomId: roomId, cursorDate: cursorDate)

            if history.data.isEmpty {
                await MainActor.run {
                    state.hasMoreMessages = false
                    state.isLoadingMore = false
                }
                return
            }

            let messageObjects = history.data.map { ChatMessageObject.from(response: $0) }
            try? await realmService.saveMessages(messageObjects)

            let newMessages = history.data.map { dto in
                ChatMessage(
                    id: dto.chatId,
                    content: dto.content ?? "",
                    senderId: dto.sender.userId,
                    senderName: dto.sender.nick,
                    senderProfileImage: dto.sender.profileImage,
                    createdAt: parseISO(dto.createdAt),
                    isMine: dto.sender.userId == userId,
                    attachment: parseAttachment(dto.files),
                    localStatus: .synced
                )
            }

            await MainActor.run {
                let existingIds = Set(self.state.messages.map { $0.id })
                let uniqueNewMessages = newMessages.filter { !existingIds.contains($0.id) }
                self.state.messages.insert(contentsOf: uniqueNewMessages, at: 0)
                self.state.messages.sort { $0.createdAt < $1.createdAt }
                self.state.isLoadingMore = false
            }
        } catch {
            await MainActor.run {
                state.isLoadingMore = false
            }
        }
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
