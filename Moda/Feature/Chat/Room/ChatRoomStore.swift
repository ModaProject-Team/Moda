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
    
    let roomId: String
    let chatAPI: ChatAPIProtocol
    let userProfileAPI: UserProfileAPIProtocol
    let socketService: ChatSocketServiceProtocol
    let realmService: ChatRealmServiceProtocol
    let networkMonitor: NetworkMonitor
    
    var myUserId: String?
    var bufferedMessages: [ChatMessageResponse] = []
    var isSocketReady = false
    var cancellables = Set<AnyCancellable>()
    var isActive = false
    
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
        
        state.participantName = participantName
        setupSocketObservers()
        setupNetworkMonitoring()
    }
    
    func send(_ intent: ChatRoomIntent) {
        switch intent {
        case .onAppear:
            isActive = true
            networkMonitor.startMonitoring()
            Task { await loadAndConnect() }
        case .onDisappear:
            isActive = false
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
            state.showImagePicker = false
            state.showSendConfirmAlert = true
            
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
            
        case .appDidEnterBackground:
            if isActive {
                disconnectSocket()
            }
            
        case .appWillEnterForeground:
            if isActive {
                Task {
                    do {
                        try await reconnectIfNeeded()
                    } catch {
                        // 재연결 실패는 UI에 반영됨
                    }
                }
            }
        }
    }
}

// MARK: - Message Sending

extension ChatRoomStore {
    func sendCurrentMessage() async {
        let text = state.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        await MainActor.run {
            state.inputText = ""
        }

        guard let userData = await prepareUserData() else { return }
        
        let tempId = "temp-\(UUID().uuidString)"
        let optimistic = createOptimisticTextMessage(tempId: tempId, text: text, userData: userData)
        
        await saveAndDisplayOptimisticMessage(optimistic)
        await sendTextMessage(tempId: tempId, text: text, userData: userData)
    }
    
    func retryFailedMessage(chatId: String) async {
        guard let failedMessage = await getFailedMessage(chatId: chatId) else { return }
        guard let userData = await prepareUserData() else { return }
        
        let newTempId = "temp-\(UUID().uuidString)"
        let optimistic = createOptimisticRetryMessage(
            newTempId: newTempId,
            failedMessage: failedMessage,
            userData: userData
        )
        
        await replaceFailedMessage(oldChatId: chatId, newOptimistic: optimistic)
        await sendTextMessage(tempId: newTempId, text: failedMessage.content, userData: userData)
    }
    
    func sendPendingFileIfNeeded() async {
        await MainActor.run {
            state.showSendConfirmAlert = false
        }

        guard case .image = state.pendingType else { return }
        guard let imageData = state.pendingImageData else { return }
        guard let userData = await prepareUserData() else { return }
        
        let tempId = "temp-\(UUID().uuidString)"
        let optimistic = createOptimisticImageMessage(tempId: tempId, userData: userData)
        
        await saveAndDisplayOptimisticMessage(optimistic)
        await sendImageMessage(tempId: tempId, imageData: imageData, userData: userData)
    }
    
    func deleteFailedMessage(chatId: String) async {
        await MainActor.run {
            state.messages.removeAll(where: { $0.id == chatId })
        }
        
        do {
            try await realmService.deleteMessage(chatId: chatId)
        } catch {
            // 삭제 실패는 무시 (다음 로드 시 정리됨)
        }
    }
    
    private func prepareUserData() async -> ChatUserData? {
        do {
            try await ensureMyUserId()
        } catch {
            setError(error)
            return nil
        }
        
        let userId = myUserId ?? ""
        guard let profile = try? await userProfileAPI.getMyProfile() else {
            return nil
        }
        
        return ChatUserData(userId: userId, profile: profile)
    }
    
    private func getFailedMessage(chatId: String) async -> ChatMessage? {
        let message = await realmService.getMessage(chatId: chatId)
        guard let message = message, message.localStatus == .failed else {
            return nil
        }
        return message
    }
    
    private func createOptimisticTextMessage(
        tempId: String,
        text: String,
        userData: ChatUserData
    ) -> OptimisticChatMessage {
        let now = Date()
        let messageObject = ChatMessageObject(
            chatId: tempId,
            roomId: roomId,
            createdAt: ISO8601DateFormatter().string(from: now),
            createdAtDate: now,
            content: text,
            senderId: userData.profile.userId,
            senderNick: userData.profile.nick,
            senderProfileImage: userData.profile.profileImage,
            filesJson: nil,
            localStatus: "sending"
        )
        
        let chatMessage = ChatMessage(
            id: tempId,
            content: text,
            senderId: userData.profile.userId,
            senderName: userData.profile.nick,
            senderProfileImage: userData.profile.profileImage,
            createdAt: now,
            isMine: true,
            attachment: nil,
            localStatus: .sending
        )
        
        return OptimisticChatMessage(realmObject: messageObject, chatMessage: chatMessage)
    }
    
    private func createOptimisticImageMessage(
        tempId: String,
        userData: ChatUserData
    ) -> OptimisticChatMessage {
        let now = Date()
        let messageObject = ChatMessageObject(
            chatId: tempId,
            roomId: roomId,
            createdAt: ISO8601DateFormatter().string(from: now),
            createdAtDate: now,
            content: nil,
            senderId: userData.profile.userId,
            senderNick: userData.profile.nick,
            senderProfileImage: userData.profile.profileImage,
            filesJson: nil,
            localStatus: "sending"
        )
        
        let chatMessage = ChatMessage(
            id: tempId,
            content: "",
            senderId: userData.profile.userId,
            senderName: userData.profile.nick,
            senderProfileImage: userData.profile.profileImage,
            createdAt: now,
            isMine: true,
            attachment: nil,
            localStatus: .sending
        )
        
        return OptimisticChatMessage(realmObject: messageObject, chatMessage: chatMessage)
    }
    
    private func createOptimisticRetryMessage(
        newTempId: String,
        failedMessage: ChatMessage,
        userData: ChatUserData
    ) -> OptimisticChatMessage {
        let now = Date()
        let messageObject = ChatMessageObject(
            chatId: newTempId,
            roomId: roomId,
            createdAt: ISO8601DateFormatter().string(from: now),
            createdAtDate: now,
            content: failedMessage.content.isEmpty ? nil : failedMessage.content,
            senderId: userData.profile.userId,
            senderNick: userData.profile.nick,
            senderProfileImage: userData.profile.profileImage,
            filesJson: nil,
            localStatus: "sending"
        )
        
        let chatMessage = ChatMessage(
            id: newTempId,
            content: failedMessage.content,
            senderId: userData.profile.userId,
            senderName: userData.profile.nick,
            senderProfileImage: userData.profile.profileImage,
            createdAt: now,
            isMine: true,
            attachment: failedMessage.attachment,
            localStatus: .sending
        )
        
        return OptimisticChatMessage(realmObject: messageObject, chatMessage: chatMessage)
    }
    
    private func saveAndDisplayOptimisticMessage(_ optimistic: OptimisticChatMessage) async {
        do {
            try await realmService.saveMessage(optimistic.realmObject)
        } catch {
            // Realm은 로컬 캐시일 뿐, 전송은 계속 진행
        }
        
        await MainActor.run {
            state.messages.append(optimistic.chatMessage)
        }
    }
    
    private func replaceFailedMessage(oldChatId: String, newOptimistic: OptimisticChatMessage) async {
        do {
            try await realmService.saveMessage(newOptimistic.realmObject)
        } catch {
            // Realm은 로컬 캐시일 뿐, 재전송은 계속 진행
        }
        
        await MainActor.run {
            state.messages.removeAll(where: { $0.id == oldChatId })
        }
        
        do {
            try await realmService.deleteMessage(chatId: oldChatId)
        } catch {
            // 이전 메시지 삭제 실패는 무시
        }
        
        await MainActor.run {
            state.messages.append(newOptimistic.chatMessage)
        }
    }
    
    private func sendTextMessage(tempId: String, text: String, userData: ChatUserData) async {
        do {
            let sent = try await sendMessageWithRetry(content: text, files: nil, retryCount: 3)
            await handleMessageSendSuccess(tempId: tempId, response: sent, userId: userData.userId)
        } catch {
            await handleMessageSendFailure(tempId: tempId)
        }
    }
    
    private func sendImageMessage(tempId: String, imageData: Data, userData: ChatUserData) async {
        do {
            let files: [FileData] = [FileData(data: imageData, type: .image)]
            let uploadResponse = try await chatAPI.uploadFiles(roomId: roomId, files: files)
            let sent = try await sendMessageWithRetry(content: nil, files: uploadResponse.files, retryCount: 3)
            await handleImageSendSuccess(tempId: tempId, response: sent, userId: userData.userId)
        } catch {
            await handleImageSendFailure(tempId: tempId)
        }
    }
    
    private func handleMessageSendSuccess(
        tempId: String,
        response: ChatMessageResponse,
        userId: String
    ) async {
        do {
            try await realmService.deleteMessage(chatId: tempId)
        } catch {
            // 임시 메시지 삭제 실패는 무시 (다음 로드 시 정리됨)
        }
        
        let actualMessage = ChatMessageObject.from(response: response)
        do {
            try await realmService.saveMessage(actualMessage)
        } catch {
            // 실제 메시지 저장 실패는 무시 (서버에는 저장됨)
        }
        
        let mapped = ChatMessage(
            id: response.chatId,
            content: response.content ?? "",
            senderId: response.sender.userId,
            senderName: response.sender.nick,
            senderProfileImage: response.sender.profileImage,
            createdAt: parseISO(response.createdAt),
            isMine: response.sender.userId == userId,
            attachment: parseAttachment(response.files),
            localStatus: .synced
        )
        
        await MainActor.run {
            if let index = state.messages.firstIndex(where: { $0.id == tempId }) {
                state.messages.remove(at: index)
                
                if !state.messages.contains(where: { $0.id == mapped.id }) {
                    state.messages.append(mapped)
                }
            }
        }
    }
    
    private func handleImageSendSuccess(
        tempId: String,
        response: ChatMessageResponse,
        userId: String
    ) async {
        await handleMessageSendSuccess(tempId: tempId, response: response, userId: userId)
        
        await MainActor.run {
            state.pendingImageData = nil
            state.pendingType = .none
        }
    }
    
    private func handleMessageSendFailure(tempId: String) async {
        do {
            try await realmService.updateMessageStatus(chatId: tempId, status: "failed")
        } catch {
            // 상태 업데이트 실패 시 UI만 업데이트
        }
        
        await MainActor.run {
            if let index = state.messages.firstIndex(where: { $0.id == tempId }) {
                let failedMessage = state.messages[index]
                state.messages[index] = ChatMessage(
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
    
    private func handleImageSendFailure(tempId: String) async {
        await handleMessageSendFailure(tempId: tempId)
        
        await MainActor.run {
            state.pendingImageData = nil
            state.pendingType = .none
        }
    }
    
    private func sendMessageWithRetry(
        content: String?,
        files: [String]?,
        retryCount: Int
    ) async throws -> ChatMessageResponse {
        var lastError: Error?
        let baseDelay: UInt64 = 500_000_000
        let maxDelay: UInt64 = 8_000_000_000
        
        for attempt in 0..<retryCount {
            do {
                return try await chatAPI.sendMessage(roomId: roomId, content: content, files: files)
            } catch {
                lastError = error
                if attempt < retryCount - 1 {
                    let exponentialDelay = baseDelay * UInt64(pow(2.0, Double(attempt)))
                    let delay = min(exponentialDelay, maxDelay)
                    do {
                        try await Task.sleep(nanoseconds: delay)
                    } catch {
                        // Task.sleep 취소는 무시
                    }
                }
            }
        }
        
        throw lastError ?? NetworkError.networkFailure
    }
}

// MARK: - Sync

extension ChatRoomStore {
    func loadAndConnect() async {
        guard !state.isLoading else { return }
        setLoading(true)
        defer { Task { setLoading(false) } }
        
        do {
            try await ensureMyUserId()
        } catch {
            // userId 조회 실패해도 로컬 메시지는 로드 시도
        }
        
        await loadLocalMessages()
        connectSocket()
        
        do {
            try await syncWithServer()
            await applyBufferedMessages()
            isSocketReady = true
        } catch {
            await MainActor.run {
                state.isNetworkError = true
            }
        }
    }
    
    func loadLocalMessages() async {
        let userId = myUserId ?? UserDefaultsManager.shared.userId ?? ""
        guard !userId.isEmpty else { return }
        
        let messages = await realmService.getMessages(roomId: roomId, limit: 100, currentUserId: userId)
        
        for message in messages where message.localStatus == .sending {
            do {
                try await realmService.updateMessageStatus(chatId: message.id, status: "failed")
            } catch {
                // 상태 업데이트 실패는 무시하고 UI만 업데이트
            }
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
            state.messages = localMessages.sorted { $0.createdAt < $1.createdAt }
        }
    }
    
    func syncWithServer() async throws {
        let userId = myUserId ?? ""
        let lastMessage = await realmService.getLastMessage(roomId: roomId)
        let cursorDate = lastMessage?.createdAt
        
        let history = try await chatAPI.getMessages(roomId: roomId, cursorDate: cursorDate)
        
        let messageObjects = history.data.map { ChatMessageObject.from(response: $0) }
        do {
            try await realmService.saveMessages(messageObjects)
        } catch {
            // Realm 저장 실패는 무시 (메모리 상태는 유지)
        }
        
        let allLocalMessages = await realmService.getMessages(roomId: roomId, limit: 100, currentUserId: userId)
        
        await MainActor.run {
            state.messages = allLocalMessages.sorted { $0.createdAt < $1.createdAt }
        }
    }
    
    func applyBufferedMessages() async {
        for dto in bufferedMessages {
            await handleRealtimeMessage(dto)
        }
        bufferedMessages.removeAll()
    }
    
    func handleRealtimeMessage(_ dto: ChatMessageResponse) async {
        let userId = myUserId ?? ""
        
        let messageObject = ChatMessageObject.from(response: dto)
        do {
            try await realmService.saveMessage(messageObject)
        } catch {
            // Realm 저장 실패해도 메모리에는 추가
        }
        
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
            if !state.messages.contains(where: { $0.id == mapped.id }) {
                state.messages.append(mapped)
            }
        }
    }
    
    func loadMoreMessages() async {
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
            do {
                try await realmService.saveMessages(messageObjects)
            } catch {
                // Realm 저장 실패는 무시
            }
            
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
                let existingIds = Set(state.messages.map { $0.id })
                let uniqueNewMessages = newMessages.filter { !existingIds.contains($0.id) }
                state.messages.insert(contentsOf: uniqueNewMessages, at: 0)
                state.messages.sort { $0.createdAt < $1.createdAt }
                state.isLoadingMore = false
            }
        } catch {
            await MainActor.run {
                state.isLoadingMore = false
            }
        }
    }
}

// MARK: - Socket

extension ChatRoomStore {
    func setupSocketObservers() {
        socketService.isConnected
            .sink { [weak self] isConnected in
                Task { @MainActor in
                    self?.state.isNetworkError = !isConnected
                }
            }
            .store(in: &cancellables)
        
        socketService.messageReceived
            .sink { [weak self] dto in
                guard let self else { return }
                
                if self.isSocketReady {
                    Task { await self.handleRealtimeMessage(dto) }
                } else {
                    self.bufferedMessages.append(dto)
                }
            }
            .store(in: &cancellables)
    }
    
    func setupNetworkMonitoring() {
        networkMonitor.$isConnected
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.state.isNetworkError {
                    self.state.isNetworkError = false
                    Task {
                        do {
                            try await self.reconnectIfNeeded()
                        } catch {
                            // 재연결 실패는 UI에 이미 반영됨
                        }
                    }
                }
            }
            .store(in: &cancellables)
        
        networkMonitor.$isConnected
            .filter { !$0 }
            .debounce(for: .seconds(3), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.state.isNetworkError = true
            }
            .store(in: &cancellables)
    }
    
    func reconnectIfNeeded() async throws {
        disconnectSocket()
        connectSocket()
        try await syncWithServer()
    }
    
    func connectSocket() {
        guard TokenManager.shared.accessToken != nil else {
            Task { @MainActor in
                self.state.errorMessage = "인증이 필요합니다."
            }
            return
        }
        socketService.connect(roomId: roomId)
    }
    
    func disconnectSocket() {
        socketService.disconnect()
    }
    
    func retryConnection() async {
        await MainActor.run {
            state.isNetworkError = false
        }

        disconnectSocket()
        connectSocket()

        do {
            try await syncWithServer()
        } catch {
            await MainActor.run {
                state.isNetworkError = true
            }
        }
    }
}

// MARK: - Helpers

extension ChatRoomStore {
    func parseISO(_ string: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: string) ?? Date()
    }
    
    func parseAttachment(_ files: [String]) -> ChatMessage.Attachment? {
        guard let firstFile = files.first, !firstFile.isEmpty else { return nil }
        let urlString = "\(NetworkConfig.baseURL)/v1\(firstFile)"
        guard let url = URL(string: urlString) else { return nil }
        return .image(url)
    }
    
    func ensureMyUserId() async throws {
        if myUserId == nil {
            let me = try await userProfileAPI.getMyProfile()
            self.myUserId = me.userId
        }
    }
    
    func setLoading(_ loading: Bool) {
        Task { @MainActor in
            state.isLoading = loading
            if loading { state.errorMessage = nil }
        }
    }

    func setError(_ error: Error) {
        Task { @MainActor in
            if let net = error as? NetworkError {
                state.errorMessage = net.localizedDescription
            } else {
                state.errorMessage = error.localizedDescription
            }
        }
    }
}
