//
//  ChatRoomView.swift
//  Moda
//
//  Created by 금가경 on 11/17/24.
//

import SwiftUI
import PhotosUI
import Kingfisher

struct ChatMessage: Identifiable {
    let id: String
    let content: String
    let senderId: String
    let senderName: String
    let senderProfileImage: String? // 상대 프로필 표시용 추가
    let createdAt: Date
    let isMine: Bool
    let attachment: Attachment?

    enum Attachment: Equatable {
        case image(URL)
    }
}

struct ChatRoomState {
    var messages: [ChatMessage] = []
    var inputText: String = ""
    var participantName: String = ""
    var isLoading: Bool = false
    var errorMessage: String?

    // 첨부 액션 시트 표시 여부
    var showAttachmentSheet: Bool = false

    // PhotosPicker 표시 상태
    var showImagePicker: Bool = false

    // Alert
    var showSendConfirmAlert: Bool = false
    var pendingImageData: Data? = nil
    var pendingType: PendingType = .none

    // 미디어 풀스크린 뷰어
    var showImageViewer: Bool = false
    var selectedImageURL: URL? = nil

    enum PendingType { case image, none }
}

enum ChatRoomIntent {
    case onAppear
    case onDisappear
    case inputTextChanged(String)
    case sendButtonTapped
    case dismissError

    // 첨부
    case attachmentButtonTapped
    case pickImage
    case attachmentSheetDismissed

    // 선택 완료
    case imagePicked(Data)

    // 피커 닫힘
    case imagePickerDismissed

    // Alert 표시/닫힘
    case showSendConfirm
    case hideSendConfirm

    // Alert 액션
    case confirmSend
    case cancelSend

    // 미디어 프리뷰
    case showImageViewer(URL)
    case hideImageViewer
}

final class ChatRoomStore: ObservableObject {
    @Published private(set) var state = ChatRoomState()

    private let roomId: String
    private let chatAPI: ChatAPIProtocol
    private let userProfileAPI: UserProfileAPIProtocol
    private let socketService: ChatSocketServiceProtocol

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
            print("SOCKET CONNECTED")
        }
        socketService.onDisconnect = {
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
                if !self.state.messages.contains(where: { $0.id == mapped.id }) {
                    self.state.messages.append(mapped)
                }
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
            try await loadMessages(cursorDate: nil)
            connectSocket()
        } catch {
            await setError(error)
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

    private func loadMessages(cursorDate: String?) async throws {
        let history = try await chatAPI.getMessages(roomId: roomId, cursorDate: cursorDate)
        let mapped = history.data.map { mapToViewModel($0) }
        await MainActor.run {
            self.state.messages = mapped.sorted { $0.createdAt < $1.createdAt }
        }
    }

    // MARK: - Send text
    private func sendCurrentMessage() async {
        let text = state.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        await MainActor.run { state.inputText = "" }

        do {
            try await ensureMyUserId()
            let sent = try await chatAPI.sendMessage(roomId: roomId, content: text, files: nil)
            let mapped = mapToViewModel(sent)
            await MainActor.run {
                if !self.state.messages.contains(where: { $0.id == mapped.id }) {
                    self.state.messages.append(mapped)
                }
            }
        } catch {
            await setError(error)
        }
    }

    // MARK: - Send image files only
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
                let mapped = mapToViewModel(sent)
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

    // MARK: - Mapping
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
            senderProfileImage: dto.sender.profileImage, // 추가
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

    // PhotosPicker 선택 항목 상태
    @State private var imageSelection: PhotosPickerItem? = nil

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
        .confirmationDialog(
            "첨부",
            isPresented: Binding(
                get: { store.state.showAttachmentSheet },
                set: { newValue in
                    if newValue == false {
                        store.send(.attachmentSheetDismissed)
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("사진 첨부") {
                store.send(.pickImage)
            }
            Button("취소", role: .cancel) { }
        }
        // 이미지 피커
        .photosPicker(
            isPresented: Binding(
                get: { store.state.showImagePicker },
                set: { newValue in
                    if newValue == false {
                        store.send(.imagePickerDismissed)
                    }
                }
            ),
            selection: Binding(
                get: { imageSelection },
                set: { newItem in
                    imageSelection = newItem
                    guard newItem != nil else { return }
                    Task { await handlePickedImage() }
                }
            ),
            matching: .images,
            preferredItemEncoding: .automatic
        )
        .alert("전송하시겠습니까?", isPresented: Binding(
            get: { store.state.showSendConfirmAlert },
            set: { newValue in
                if newValue == false {
                    store.send(.hideSendConfirm)
                } else {
                    store.send(.showSendConfirm)
                }
            }
        )) {
            Button("취소", role: .cancel) {
                store.send(.cancelSend)
            }
            Button("전송", role: .destructive) {
                store.send(.confirmSend)
            }
        } message: {
            Text(alertMessage)
        }
        // 이미지 전체 보기
        .fullScreenCover(isPresented: Binding(
            get: { store.state.showImageViewer },
            set: { newValue in
                if newValue == false { store.send(.hideImageViewer) }
            }
        )) {
            if let url = store.state.selectedImageURL {
                ImageViewer(url: url) {
                    store.send(.hideImageViewer)
                }
            }
        }
    }

    private var alertMessage: String {
        switch store.state.pendingType {
        case .image:
            return "선택한 사진을 전송합니다."
        case .none:
            return ""
        }
    }

    private func handlePickedImage() async {
        guard let item = imageSelection else { return }
        defer { imageSelection = nil }
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                store.send(.imagePicked(data))
            }
        } catch {
            print("이미지 로드 실패: \(error)")
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
                LazyVStack(spacing: 10) {
                    ForEach(store.state.messages) { message in
                        MessageBubble(
                            message: message,
                            onTapImage: { url in store.send(.showImageViewer(url)) }
                        )
                        .id(message.id)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
            .onAppear {
                if let lastMessage = store.state.messages.last {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .top)
                        }
                    }
                }
            }
            .onChange(of: store.state.messages.count) {
                if let lastMessage = store.state.messages.last {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            proxy.scrollTo(lastMessage.id, anchor: .top)
                        }
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
                    store.send(.attachmentButtonTapped)
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
    let onTapImage: (URL) -> Void

    private let maxBubbleWidth: CGFloat = 220

    var body: some View {
        Group {
            if message.isMine {
                HStack {
                    Spacer(minLength: 60)
                    HStack(alignment: .bottom, spacing: 6) {
                        timeLabel
                        bubbleContent
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                // 친구 메시지: 왼쪽 프로필, 오른쪽에 닉네임 + 버블/시간
                HStack(alignment: .top, spacing: 8) {
                    profileImage
                    VStack(alignment: .leading, spacing: 4) {
                        Text(message.senderName)
                            .Body2()
                            .foregroundColor(.gray2)

                        HStack(alignment: .bottom, spacing: 6) {
                            bubbleContent
                            timeLabel
                        }
                    }
                    Spacer(minLength: 40)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var profileImage: some View {
        Group {
            if let path = message.senderProfileImage, !path.isEmpty {
                KFImage(URL(string: "\(NetworkConfig.baseURL)/v1\(path)"))
                    .requestModifier(KFHeaders.modifier)
                    .placeholder {
                        Circle().fill(Color.gray3)
                    }
                    .cacheOriginalImage()
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray3)
                    .frame(width: 32, height: 32)
            }
        }
    }

    @ViewBuilder
    private var bubbleContent: some View {
        switch message.attachment {
        case .none:
            textBubble
        case .image(let url):
            if message.isMine {
                HStack(alignment: .bottom, spacing: 6) {
                    mediaBubble {
                        KFImage(url)
                            .requestModifier(KFHeaders.modifier)
                            .placeholder {
                                RoundedRectangle(cornerRadius: 12).fill(Color.gray5)
                                    .frame(width: maxBubbleWidth, height: maxBubbleWidth * 0.6)
                            }
                            .cacheOriginalImage()
                            .resizable()
                            .scaledToFill()
                            .frame(width: maxBubbleWidth, height: maxBubbleWidth * 0.6)
                            .clipped()
                    }
                    .onTapGesture { onTapImage(url) }
                }
            } else {
                HStack(alignment: .bottom, spacing: 6) {
                    mediaBubble {
                        KFImage(url)
                            .requestModifier(KFHeaders.modifier)
                            .placeholder {
                                RoundedRectangle(cornerRadius: 12).fill(Color.gray5)
                                    .frame(width: maxBubbleWidth, height: maxBubbleWidth * 0.6)
                            }
                            .cacheOriginalImage()
                            .resizable()
                            .scaledToFill()
                            .frame(width: maxBubbleWidth, height: maxBubbleWidth * 0.6)
                            .clipped()
                    }
                    .onTapGesture { onTapImage(url) }
                }
            }
        }
    }

    private var textBubble: some View {
        HStack(alignment: .bottom, spacing: 0) {
            Text(message.content)
                .Body1()
                .foregroundColor(message.isMine ? .white : .gray1)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(message.isMine ? Color.blue1 : Color.gray5)
                .cornerRadius(16)
        }
    }

    private func mediaBubble<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .background(message.isMine ? Color.blue1 : Color.gray5)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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

// MARK: - Full screen viewers

struct ImageViewer: View {
    let url: URL
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            KFImage(url)
                .requestModifier(KFHeaders.modifier)
                .placeholder { ProgressView().tint(.white) }
                .cacheOriginalImage()
                .resizable()
                .scaledToFit()
                .ignoresSafeArea()
            VStack {
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    Spacer()
                }
                .padding()
                Spacer()
            }
        }
    }
}

#Preview {
    ChatRoomView(roomId: "1", participantName: "김민수")
        .environmentObject(AppNavigator.shared)
}
