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

extension ChatMessage {
    static func mockData(for roomId: String) -> [ChatMessage] {
        let myUserId = "myUserId"
        let opponentId = "opponentId"

        return [
            ChatMessage(
                id: "1",
                content: "야 그거 아직 있어?",
                senderId: opponentId,
                senderName: "상대방",
                createdAt: Date().addingTimeInterval(-3600),
                isMine: false
            ),
            ChatMessage(
                id: "2",
                content: "ㅇㅇ 있어",
                senderId: myUserId,
                senderName: "나",
                createdAt: Date().addingTimeInterval(-3500),
                isMine: true
            ),
            ChatMessage(
                id: "3",
                content: "상태 어때?",
                senderId: opponentId,
                senderName: "상대방",
                createdAt: Date().addingTimeInterval(-3400),
                isMine: false
            ),
            ChatMessage(
                id: "4",
                content: "거의 새거야 몇 번 안 씀",
                senderId: myUserId,
                senderName: "나",
                createdAt: Date().addingTimeInterval(-3300),
                isMine: true
            ),
            ChatMessage(
                id: "5",
                content: "ㅇㅋ 직접 만나서 거래 가능?",
                senderId: opponentId,
                senderName: "상대방",
                createdAt: Date().addingTimeInterval(-1800),
                isMine: false
            ),
            ChatMessage(
                id: "6",
                content: "ㄱㄱ 언제 돼?",
                senderId: myUserId,
                senderName: "나",
                createdAt: Date().addingTimeInterval(-1700),
                isMine: true
            ),
            ChatMessage(
                id: "7",
                content: "내일 3시 ㄱ?",
                senderId: opponentId,
                senderName: "상대방",
                createdAt: Date().addingTimeInterval(-600),
                isMine: false
            ),
            ChatMessage(
                id: "8",
                content: "ㅇㅋ 어디서 볼까",
                senderId: myUserId,
                senderName: "나",
                createdAt: Date().addingTimeInterval(-300),
                isMine: true
            )
        ]
    }
}

struct ChatRoomState {
    var messages: [ChatMessage] = []
    var inputText: String = ""
    var participantName: String = ""
}

enum ChatRoomIntent {
    case inputTextChanged(String)
    case sendButtonTapped
}

final class ChatRoomStore: ObservableObject {
    @Published private(set) var state = ChatRoomState()

    init(roomId: String, participantName: String) {
        state.messages = ChatMessage.mockData(for: roomId)
        state.participantName = participantName
    }

    func send(_ intent: ChatRoomIntent) {
        switch intent {
        case .inputTextChanged(let text):
            state.inputText = text
        case .sendButtonTapped:
            guard !state.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

            let newMessage = ChatMessage(
                id: UUID().uuidString,
                content: state.inputText,
                senderId: "myUserId",
                senderName: "나",
                createdAt: Date(),
                isMine: true
            )

            state.messages.append(newMessage)
            state.inputText = ""
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
                messageListSection
                inputSection
            }
        }
        .navigationBarHidden(true)
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
