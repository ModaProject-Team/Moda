//
//  ChatRoomView.swift
//  Moda
//
//  Created by 금가경 on 11/17/24.
//

import SwiftUI
import PhotosUI

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
                } else {
                    messageListSection
                }

                inputSection
            }
        }
        .onTapGesture {
            hideKeyboard()
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
                .H2()
                .foregroundColor(.gray1)

            Spacer()
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
        ZStack(alignment: .top) {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        if store.state.isLoadingMore {
                            loadingMoreIndicator
                        }

                        ForEach(store.state.sortedMessages) { message in
                            MessageBubble(
                                message: message,
                                onTapImage: { url in store.send(.showImageViewer(url)) },
                                onRetry: { chatId in store.send(.retryMessage(chatId)) },
                                onDelete: { chatId in store.send(.deleteMessage(chatId)) }
                            )
                            .id(message.id)
                            .onAppear {
                                if message.id == store.state.sortedMessages.first?.id && store.state.hasMoreMessages {
                                    store.send(.loadMoreMessages)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .padding(.top, store.state.isNetworkError ? 50 : 0)
                }
            .onAppear {
                if let lastMessage = store.state.sortedMessages.last {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .top)
                        }
                    }
                }
            }
            .onChange(of: store.state.messages.count) {
                if let lastMessage = store.state.sortedMessages.last {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            proxy.scrollTo(lastMessage.id, anchor: .top)
                        }
                    }
                }
            }
            }

            if store.state.isNetworkError {
                networkErrorBanner
            }
        }
    }

    private var loadingMoreIndicator: some View {
        HStack {
            Spacer()
            ProgressView()
                .padding(.vertical, 8)
            Spacer()
        }
    }

    private var networkErrorBanner: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.white)
                    .font(.system(size: 14))

                Text("네트워크가 연결되지 않았습니다")
                    .Body2()
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.red.opacity(0.9))
        }
    }

    private var inputSection: some View {
        VStack(spacing: 0) {
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
    let onRetry: (String) -> Void
    let onDelete: (String) -> Void

    private let maxBubbleWidth: CGFloat = 220

    var body: some View {
        Group {
            if message.isMine {
                HStack {
                    Spacer(minLength: 60)
                    HStack(alignment: .bottom, spacing: 6) {
                        statusIndicator
                        timeLabel
                        bubbleContent
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
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

    @ViewBuilder
    private var statusIndicator: some View {
        if message.isMine {
            switch message.localStatus {
            case .sending:
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.gray3)
                    .font(.system(size: 12))
                    .rotationEffect(.degrees(225))
            case .failed:
                HStack(spacing: 4) {
                    Button {
                        onRetry(message.id)
                    } label: {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 16))
                    }
                    Button {
                        onDelete(message.id)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray3)
                            .font(.system(size: 16))
                    }
                }
            case .synced:
                EmptyView()
            }
        }
    }

    private var profileImage: some View {
        Group {
            if let path = message.senderProfileImage, !path.isEmpty {
                CachedImageView(
                    url: URL(string: "\(NetworkConfig.baseURL)/v1\(path)"),
                    targetSize: CGSize(width: 32, height: 32),
                    contentMode: .fill,
                    placeholder: {
                        AnyView(Circle().fill(Color.gray3))
                    }
                )
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
                        CachedImageView(
                            url: url,
                            contentMode: .fill,
                            placeholder: {
                                AnyView(
                                    RoundedRectangle(cornerRadius: 12).fill(Color.gray5)
                                        .frame(width: maxBubbleWidth, height: maxBubbleWidth * 0.6)
                                )
                            }
                        )
                        .frame(width: maxBubbleWidth, height: maxBubbleWidth * 0.6)
                        .clipped()
                    }
                    .onTapGesture { onTapImage(url) }
                }
            } else {
                HStack(alignment: .bottom, spacing: 6) {
                    mediaBubble {
                        CachedImageView(
                            url: url,
                            contentMode: .fill,
                            placeholder: {
                                AnyView(
                                    RoundedRectangle(cornerRadius: 12).fill(Color.gray5)
                                        .frame(width: maxBubbleWidth, height: maxBubbleWidth * 0.6)
                                )
                            }
                        )
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
            CachedImageView(
                url: url,
                contentMode: .fit,
                placeholder: {
                    AnyView(ProgressView().tint(.white))
                }
            )
            .cacheOriginalImage()
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
