//
//  ChatRoomView.swift
//  Moda
//
//  Created by 금가경 on 11/17/24.
//

import SwiftUI

struct ChatMessage: Identifiable {
    let id: String
    let content: String
    let senderId: String
    let senderName: String
    let createdAt: Date
    let isMine: Bool
}

struct ChatRoomState {
    var messages: [ChatMessage] = []
    var inputText: String = ""
    var participantName: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
}

enum ChatRoomIntent {
    case onAppear
    case onDisappear
    case inputTextChanged(String)
    case sendButtonTapped
    case dismissError
}

final class ChatRoomStore: ObservableObject {
    @Published private(set) var state = ChatRoomState()

    private let roomId: String
    private let chatAPI: ChatAPIProtocol
    private let userProfileAPI: UserProfileAPIProtocol
    private let socketService: ChatSocketServiceProtocol

    // 내 사용자 ID (보낸 사람 판별용)
    private var myUserId: String?

    init(
        roomId: String,
        participantName: String,
        chatAPI: ChatAPIProtocol = ChatAPI.shared,
        userProfileAPI: UserProfileAPIProtocol = UserProfileAPI.shared,
        socketService: ChatSocketServiceProtocol = ChatSocketService()
    ) {
        self.roomId = roomId
        self.chatAPI = chatAPI
        self.userProfileAPI = userProfileAPI
        self.socketService = socketService
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
        }
    }

    private func setupSocketCallbacks() {
        socketService.onConnect = { [weak self] in
            print("SOCKET CONNECTED")
        }
        socketService.onDisconnect = { [weak self] in
            print("SOCKET DISCONNECTED")
        }
        socketService.onError = { [weak self] message in
            Task { @MainActor in
                self?.state.errorMessage = message
            }
        }
        socketService.onChat = { [weak self] dto in
            guard let self else { return }
            let mapped = self.mapToViewModel(dto)
            Task { @MainActor in
                self.state.messages.append(mapped)
            }
        }
    }

    // MARK: - Load + Socket
    private func loadAndConnect() async {
        guard !state.isLoading else { return }
        await setLoading(true)
        defer { Task { await setLoading(false) } }

        do {
            try await ensureMyUserId()
            try await loadMessages(cursorDate: nil) // 초기 로드(현재는 전체/최신 정책에 맞춰 서버가 반환)
            connectSocket()
        } catch {
            await setError(error)
        }
    }

    private func connectSocket() {
        // 토큰이 없으면 연결 시도하지 않음
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

    private func loadMessages(cursorDate: String?) async throws {
        let history = try await chatAPI.getMessages(roomId: roomId, cursorDate: cursorDate)
        let mapped = history.data.map { mapToViewModel($0) }
        await MainActor.run {
            self.state.messages = mapped.sorted { $0.createdAt < $1.createdAt }
        }
    }

    // MARK: - Send
    private func sendCurrentMessage() async {
        let text = state.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        await MainActor.run { state.inputText = "" }

        do {
            try await ensureMyUserId()
            let sent = try await chatAPI.sendMessage(roomId: roomId, content: text, files: nil)
            let mapped = mapToViewModel(sent)
            await MainActor.run {
                self.state.messages.append(mapped)
            }
        } catch {
            await setError(error)
        }
    }

    // MARK: - Mapping
    private func mapToViewModel(_ dto: ChatMessageResponse) -> ChatMessage {
        let created = parseISODate(dto.createdAt)
        let myId = myUserId ?? ""
        let isMine = (dto.sender.userId == myId)

        let text: String
        if let content = dto.content, !content.isEmpty {
            text = content
        } else {
            text = dto.files.isEmpty ? "" : "파일"
        }

        return ChatMessage(
            id: dto.chatId,
            content: text,
            senderId: dto.sender.userId,
            senderName: dto.sender.nick,
            createdAt: created,
            isMine: isMine
        )
    }

    private func parseISODate(_ string: String) -> Date {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return iso.date(from: string) ?? Date()
    }

    // MARK: - UI State helpers
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

struct ChatRoomView: View {
    @StateObject private var store: ChatRoomStore
    @EnvironmentObject var navigator: AppNavigator
    @FocusState private var isInputFocused: Bool

    init(roomId: String, participantName: String) {
        _store = StateObject(wrappedValue: ChatRoomStore(roomId: roomId, participantName: participantName))
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection

                if store.state.isLoading {
                    loadingSection
                } else if let message = store.state.errorMessage {
                    errorSection(message: message)
                } else {
                    messageListSection
                }

                inputSection
            }
        }
        .navigationBarHidden(true)
        .task {
            store.send(.onAppear)
        }
        .onDisappear {
            store.send(.onDisappear)
        }
    }

    private var headerSection: some View {
        HStack {
            Button {
                navigator.pop()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18))
                    .foregroundColor(.gray1)
            }

            Spacer()

            Text(store.state.participantName)
                .H1()
                .foregroundColor(.gray1)

            Spacer()

            Button {
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18))
                    .foregroundColor(.gray1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
    }

    private var loadingSection: some View {
        VStack {
            Spacer()
            ProgressView()
            Spacer()
        }
    }

    private func errorSection(message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Text(message)
                .Body1()
                .foregroundColor(.gray2)
            Button("다시 시도") {
                store.send(.onAppear)
            }
            .buttonStyle(.bordered)
            Spacer()
        }
    }

    private var messageListSection: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    ForEach(store.state.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: store.state.messages.count) {
                if let lastMessage = store.state.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var inputSection: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 12) {
                Button {
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20))
                        .foregroundColor(.gray2)
                }

                TextField("메시지를 입력하세요", text: Binding(
                    get: { store.state.inputText },
                    set: { store.send(.inputTextChanged($0)) }
                ))
                .Input()
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.gray5)
                .cornerRadius(20)
                .focused($isInputFocused)

                Button {
                    store.send(.sendButtonTapped)
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(store.state.inputText.isEmpty ? .gray3 : .blue1)
                }
                .disabled(store.state.inputText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.white)
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isMine {
                Spacer(minLength: 60)
                timeLabel
                bubbleContent
            } else {
                bubbleContent
                timeLabel
                Spacer(minLength: 60)
            }
        }
    }

    private var bubbleContent: some View {
        Text(message.content)
            .Body1()
            .foregroundColor(message.isMine ? .white : .gray1)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(message.isMine ? Color.blue1 : Color.gray5)
            .cornerRadius(16)
    }

    private var timeLabel: some View {
        Text(formatTime(message.createdAt))
            .font(.system(size: 11))
            .foregroundColor(.gray3)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a h:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}

#Preview {
    ChatRoomView(roomId: "1", participantName: "김민수")
        .environmentObject(AppNavigator.shared)
}
