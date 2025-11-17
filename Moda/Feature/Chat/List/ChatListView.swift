//
//  ChatListView.swift
//  Moda
//
//  Created by 금가경 on 11/17/24.
//

import SwiftUI

struct ChatRoom: Identifiable {
    let id: String
    let participantName: String
    let participantProfileImage: String?
    let lastMessage: String
    let lastMessageTime: Date
    let unreadCount: Int
}

extension ChatRoom {
    static let mockData: [ChatRoom] = [
        ChatRoom(
            id: "1",
            participantName: "김민수",
            participantProfileImage: nil,
            lastMessage: "ㅇㅋ 내일 3시 ㄱㄱ",
            lastMessageTime: Date().addingTimeInterval(-300),
            unreadCount: 2
        ),
        ChatRoom(
            id: "2",
            participantName: "이서연",
            participantProfileImage: nil,
            lastMessage: "야 그거 아직 있어?",
            lastMessageTime: Date().addingTimeInterval(-3600),
            unreadCount: 0
        ),
        ChatRoom(
            id: "3",
            participantName: "박지훈",
            participantProfileImage: nil,
            lastMessage: "ㄹㅇ? 좀 깎아줘 ㅋㅋ",
            lastMessageTime: Date().addingTimeInterval(-86400),
            unreadCount: 1
        ),
        ChatRoom(
            id: "4",
            participantName: "최유진",
            participantProfileImage: nil,
            lastMessage: "ㄱㅅㄱㅅ 잘 받았어!",
            lastMessageTime: Date().addingTimeInterval(-172800),
            unreadCount: 0
        )
    ]
}

struct ChatListState {
    var chatRooms: [ChatRoom] = ChatRoom.mockData
}

enum ChatListIntent {
    case chatRoomTapped(ChatRoom)
}

final class ChatListStore: ObservableObject {
    @Published private(set) var state = ChatListState()

    func send(_ intent: ChatListIntent) {
        switch intent {
        case .chatRoomTapped:
            break
        }
    }
}

struct ChatListView: View {
    @StateObject private var store = ChatListStore()
    @EnvironmentObject var navigator: AppNavigator

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection

                if store.state.chatRooms.isEmpty {
                    emptyStateSection
                } else {
                    chatListSection
                }
            }
        }
    }

    private var headerSection: some View {
        HStack {
            Text("채팅")
                .H1()
                .foregroundColor(.gray1)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
    }

    private var emptyStateSection: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundColor(.gray3)

            Text("아직 대화가 없어요")
                .Body1()
                .foregroundColor(.gray2)

            Spacer()
        }
    }

    private var chatListSection: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(store.state.chatRooms) { room in
                    ChatRoomCell(room: room) {
                        navigator.push(.chatRoom(roomId: room.id, participantName: room.participantName))
                    }

                    Divider()
                        .padding(.leading, 76)
                }
            }
            .padding(.bottom, 100)
        }
    }
}

struct ChatRoomCell: View {
    let room: ChatRoom
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                profileImageSection
                contentSection
                timeAndBadgeSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private var profileImageSection: some View {
        Circle()
            .fill(Color.gray3)
            .frame(width: 52, height: 52)
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(room.participantName)
                .H2()
                .foregroundColor(.gray1)

            Text(room.lastMessage)
                .Body2()
                .foregroundColor(.gray2)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var timeAndBadgeSection: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(formatTime(room.lastMessageTime))
                .Body2()
                .foregroundColor(.gray3)

            if room.unreadCount > 0 {
                Text("\(room.unreadCount)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue1)
                    .clipShape(Capsule())
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "a h:mm"
            formatter.locale = Locale(identifier: "ko_KR")
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "어제"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M월 d일"
            return formatter.string(from: date)
        }
    }
}

#Preview {
    ChatListView()
        .environmentObject(AppNavigator.shared)
}
