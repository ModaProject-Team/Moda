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


// MARK: - Mainview
struct FriendListView: View {
    @State private var store = FriendListStore()
    // 네비게이션
    @EnvironmentObject var navigator: AppNavigator

    var body: some View {
        List {
            // 내 프로필 섹션
            Section {
                if let my = store.myPeople {
                    MyProfileHeader(people: my)
                        .onTapGesture {
                            // 내 프로필 상세
                            navigator.push(.profileDetail)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                } else {
                    // 로딩 중/미표시 상태용 플레이스홀더
                    MyProfilePlaceholder()
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }

            // 친구 섹션(맞팔만)
            Section {
                let friendPeople = store.friendPeople
                if friendPeople.isEmpty {
                    EmptyFriendsView()
                } else {
                    ForEach(friendPeople) { person in
                        FriendRow(people: person)
                            .onTapGesture {
                                // 친구 프로필 상세로 이동 시 userId를 넘겨서 OtherProfile 로드 가능
                                navigator.push(.profileDetail)
                            }
                    }
                }
            } header: {
                Text("친구 \(store.friendPeople.count)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.plain)
        .navigationTitle("친구")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    navigator.push(.friendSearch(friends: store.friendPeople))
                } label: {
                    Image(systemName: "magnifyingglass")
                }

                Button {
                    navigator.push(.friendAdd)
                } label: {
                    Image(systemName: "person.badge.plus")
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
}

// MARK: - Subviews
private struct MyProfileHeader: View {
    let people: People

    var body: some View {
        HStack(spacing: 14) {
            ProfileImageView(people: people)
                .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(people.name)
                    .font(.title3.weight(.semibold))

                if let msg = people.statusMessage, !msg.isEmpty {
                    Text(msg)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

private struct MyProfilePlaceholder: View {
    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 16)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 180, height: 14)
            }
            Spacer()
        }
        .padding(.vertical, 6)
        .redacted(reason: .placeholder)
    }
}

private struct FriendRow: View {
    let people: People

    var body: some View {
        HStack(spacing: 12) {
            ProfileImageView(people: people)
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(people.name)
                    .font(.body.weight(.semibold))

                if let msg = people.statusMessage, !msg.isEmpty {
                    Text(msg)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

private struct EmptyFriendsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("아직 친구가 없습니다")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
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
