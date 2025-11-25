//
//  FriendListView.swift
//  Moda
//
//  Created by You on 11/10/25.
//

import SwiftUI
import Kingfisher
import Observation

// MARK: - Model (View 전용 표시 모델)
struct People: Identifiable, Hashable {
    let id: String
    var name: String
    var statusMessage: String?
    var profileImageURL: URL?
}

// MARK: - State (원본 DTO를 보관)
struct FriendListState {
    var myProfile: MyProfileResponse?
    var friends: [OtherProfileResponse] = []
    var isLoading: Bool = false
    var errorMessage: String?
}

// MARK: - Intent
enum FriendListAction {
    case onAppear
    case refresh
    case dismissError
}

// MARK: - Store
@MainActor
@Observable
final class FriendListStore {
    private(set) var state = FriendListState()
    private let userProfileAPI: UserProfileAPIProtocol = UserProfileAPI.shared

    // 파생 상태(표시용)
    var myPeople: People? {
        guard let my = state.myProfile else { return nil }
        return People(
            id: my.userId,
            name: my.nick,
            statusMessage: my.info1,
            profileImageURL: URL(string: "\(NetworkConfig.baseURL)/v1\(my.profileImage ?? "")")
        )
    }

    var friendPeople: [People] {
        state.friends.map { friend in
            People(
                id: friend.userId,
                name: friend.nick,
                statusMessage: friend.info1,
                profileImageURL: URL(string: "\(NetworkConfig.baseURL)/v1\(friend.profileImage ?? "")")
            )
        }
    }

    func send(_ action: FriendListAction) {
        switch action {
        case .onAppear, .refresh:
            Task { await load() }
        case .dismissError:
            state.errorMessage = nil
        }
    }

    // MARK: - Side Effects
    private func load() async {
        guard !state.isLoading else { return }
        state.isLoading = true
        defer { state.isLoading = false }

        do {
            // 1) 내 프로필 조회 (DTO 그대로 사용)
            let dto = try await userProfileAPI.getMyProfile()
            state.myProfile = dto

            // 2) 맞팔 계산: followers ∩ following (userId 기준)
            let followerIDs = Set(dto.followers.map { $0.userId })
            let followingIDs = Set(dto.following.map { $0.userId })
            let mutualIDs = Array(followerIDs.intersection(followingIDs))

            // 3) 맞팔 사용자 상세 정보 조회(OtherProfileResponse)
            var details: [OtherProfileResponse] = []
            for id in mutualIDs {
                do {
                    let profile = try await userProfileAPI.getUserProfile(userId: id)
                    details.append(profile)
                } catch {
                    // 개별 친구 상세 조회 실패는 스킵
                    continue
                }
            }

            // 4) 보기 좋게 닉네임 기준 정렬
            state.friends = details.sorted {
                $0.nick.localizedCaseInsensitiveCompare($1.nick) == .orderedAscending
            }

        } catch {
            if let netErr = error as? NetworkError {
                state.errorMessage = netErr.localizedDescription
            } else {
                state.errorMessage = error.localizedDescription
            }
        }
    }
}


struct FriendListView: View {
    @State private var store = FriendListStore()
    @EnvironmentObject var navigator: AppNavigator

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        myProfileSection
                        friendListSection
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .task {
            store.send(.onAppear)
        }
        .refreshable {
            store.send(.refresh)
        }
        .alert(
            "오류",
            isPresented: Binding(
                get: { store.state.errorMessage != nil },
                set: { if !$0 { store.send(.dismissError) } }
            ),
            actions: {
                Button("확인", role: .cancel) {
                    store.send(.dismissError)
                }
            },
            message: {
                Text(store.state.errorMessage ?? "")
            }
        )
    }

    private var headerSection: some View {
        HStack(spacing: 20) {
            Text("친구")
                .H1()
                .foregroundColor(.gray1)

            Spacer()

            Button {
                navigator.push(.friendSearch(friends: store.friendPeople))
            } label: {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray1)
            }

            Button {
                navigator.push(.friendAdd)
            } label: {
                Image(systemName: "person.badge.plus")
                    .foregroundColor(.gray1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
    }

    private var myProfileSection: some View {
        VStack(spacing: 0) {
            if let my = store.myPeople {
                MyProfileCell(people: my) {
                    navigator.push(.profileDetail(people: my, isCurrentUser: true))
                }
            } else {
                MyProfilePlaceholder()
            }
        }
    }

    private var friendListSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("친구 \(store.friendPeople.count)")
                    .Body2()
                    .foregroundColor(.gray2)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            let friendPeople = store.friendPeople
            if friendPeople.isEmpty {
                emptyFriendsSection
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(friendPeople) { person in
                        FriendCell(people: person) {
                            navigator.push(.profileDetail(people: person, isCurrentUser: false))
                        }
                    }
                }
            }
        }
    }

    private var emptyFriendsSection: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "person.2")
                .font(.system(size: 48))
                .foregroundColor(.gray3)

            Text("아직 친구가 없어요")
                .Body1()
                .foregroundColor(.gray2)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: UIScreen.main.bounds.height - 300)
    }
}

private struct MyProfileCell: View {
    let people: People
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                profileImageSection
                contentSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private var profileImageSection: some View {
        ProfileImageView(people: people)
            .frame(width: 52, height: 52)
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(people.name)
                .H2()
                .foregroundColor(.gray1)

            if let msg = people.statusMessage, !msg.isEmpty {
                Text(msg)
                    .Body2()
                    .foregroundColor(.gray2)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MyProfilePlaceholder: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray3)
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray3)
                    .frame(width: 120, height: 18)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray3)
                    .frame(width: 180, height: 14)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .redacted(reason: .placeholder)
    }
}

private struct FriendCell: View {
    let people: People
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                profileImageSection
                contentSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private var profileImageSection: some View {
        ProfileImageView(people: people)
            .frame(width: 52, height: 52)
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(people.name)
                .H2()
                .foregroundColor(.gray1)

            if let msg = people.statusMessage, !msg.isEmpty {
                Text(msg)
                    .Body2()
                    .foregroundColor(.gray2)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ProfileImageView: View {
    let people: People

    var body: some View {
        if let url = people.profileImageURL {
            KFImage(url)
                .requestModifier(KFHeaders.modifier)
                .placeholder { placeholder }
                .cacheOriginalImage()
                .fade(duration: 0.2)
                .cancelOnDisappear(true)
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
        } else {
            // 이미지 불러와지지 않을때 임시 이미지.
            ZStack {
                Circle().fill(Color.gray.opacity(0.2))
                Image(systemName: "person.fill")
            }
            .clipShape(Circle())
        }
    }

    private var placeholder: some View {
        Circle().fill(Color.gray.opacity(0.2))
    }
}

#Preview {
    NavigationStack {
        FriendListView()
    }
    .environmentObject(AppNavigator.shared)
}
