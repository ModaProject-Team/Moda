//
//  ChatListView.swift
//  Moda
//
//  Created by 금가경 on 11/17/24.
//

import SwiftUI

struct ChatListView: View {
    @StateObject private var store = ChatListStore()
    @EnvironmentObject var navigator: AppNavigator

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
                } else if store.state.chatRooms.isEmpty {
                    emptyStateSection
                } else {
                    chatListSection
                }
            }
        }
        .task {
            // 화면 진입 시 최초 로드
            store.send(.loadRooms)
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
                store.send(.refresh)
            }
            .buttonStyle(.bordered)
            Spacer()
        }
    }

    private var emptyStateSection: some View {
        VStack {
            Spacer()
            EmptyStateView(message: "아직 대화가 없어요")
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
                }
            }
            .padding(.bottom, 100)
        }
        .refreshable {
            store.send(.refresh)
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
        let imageURL: URL? = {
            if let path = room.participantProfileImage, !path.isEmpty {
                return URL(string: "\(NetworkConfig.baseURL)/v1\(path)")
            }
            return nil
        }()

        return ProfileImageView(imageURL: imageURL, size: 52)
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
