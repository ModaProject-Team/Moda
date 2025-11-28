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

struct ChatListState {
    var chatRooms: [ChatRoom] = []
    var isLoading: Bool = false
    var errorMessage: String?
}

enum ChatListIntent {
    case chatRoomTapped(ChatRoom)
    case loadRooms
    case refresh
}

final class ChatListStore: ObservableObject {
    @Published private(set) var state = ChatListState()

    private let chatAPI: ChatAPIProtocol
    private let userProfileAPI: UserProfileAPIProtocol

    // 내 사용자 ID (상대방 판별용)
    private var myUserId: String?

    init(
        chatAPI: ChatAPIProtocol = ChatAPI.shared,
        userProfileAPI: UserProfileAPIProtocol = UserProfileAPI.shared
    ) {
        self.chatAPI = chatAPI
        self.userProfileAPI = userProfileAPI
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
        // 서버 createdAt/updatedAt이 ISO8601 형식이라고 가정
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return iso.date(from: string) ?? Date()
    }

    private func mapToViewModel(_ dto: ChatRoomResponse) -> ChatRoom {
        let opponent: ChatParticipant?
        if let myId = myUserId {
            opponent = dto.participants.first(where: { $0.userId != myId }) ?? dto.participants.first
        } else {
            //MARK: 만약 대화 참여자 조회시 내 아이디가 없으면 상대가 말 건 것으로 간주, 첫 참여자를 상대로 뒀음, 나중애 필요하면 수정하기
            opponent = dto.participants.first
        }

        // 마지막 메시지 텍스트/시간
        let lastMessageText: String
        let lastMessageTime: Date
        if let last = dto.lastChat {
            if let content = last.content, !content.isEmpty {
                //MARK: TODO 라스트쳇 요청후 "{닉네임} {대화내용} 형태로 나오는것 확인됨, 추후 닉네임 부분 제거하는 로직 추가하기"
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
            lastMessageTime: lastMessageTime,
            unreadCount: 0 // API 명세에 없으므로 일단 0으로 처리
        )
    }

    @MainActor
    private func applyRooms(_ rooms: [ChatRoomResponse]) {
        self.state.chatRooms = rooms.map(mapToViewModel)
    }

    // 내 userId를 보장
    private func ensureMyUserId() async throws {
        if myUserId == nil {
            let me = try await userProfileAPI.getMyProfile()
            self.myUserId = me.userId
        }
    }

    private func loadRooms() async {
        await setLoading(true)
        do {
            // 내 ID 확보 후 방 목록 불러오기
            try await ensureMyUserId()
            let response = try await chatAPI.getRooms()
            await applyRooms(response.data)
            await setLoading(false)
        } catch {
            await MainActor.run {
                self.state.errorMessage = (error as? NetworkError)?.localizedDescription ?? "채팅방을 불러오지 못했어요."
                self.state.isLoading = false
            }
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
        VStack(spacing: 12) {
            Spacer()

            EmptyStateView(message: "아직 대화가 없어요")

            Button("새로고침") {
                store.send(.refresh)
            }
            .buttonStyle(.bordered)

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
