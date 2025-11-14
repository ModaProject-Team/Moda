//
//  FriendListView.swift
//  Moda
//
//  Created by You on 11/10/25.
//

import SwiftUI
import Kingfisher

// MARK: - Model
private struct People: Identifiable, Hashable {
    let id: UUID
    var name: String
    var statusMessage: String?
    var profileImageURL: URL?
}

// 프로필 이미지 제너레이터
private func generateDummyProfileImageURL(size: Int = 180) -> URL? {
    URL(string: "https://picsum.photos/seed/\(Int.random(in: 1...100))/\(size)")
}

// MARK: - Mainview
struct FriendListView: View {
    @State private var myProfile: People = People(
        id: UUID(),
        name: "모건",
        statusMessage: "상태 메시지 예시 입니다.",
        profileImageURL: generateDummyProfileImageURL()
    )

    // 친구 목록 (더미데이터)
    @State private var friends: [People] = [
        People(id: UUID(), name: "영훈", statusMessage: "주말엔 등산!", profileImageURL: generateDummyProfileImageURL(size: 200)),
        People(id: UUID(), name: "지민", statusMessage: "Swift 즐겨요", profileImageURL: generateDummyProfileImageURL(size: 200)),
        People(id: UUID(), name: "수빈", statusMessage: "오늘도 화이팅오늘도 화이팅오늘도 화이팅오늘도 화이팅오늘도 화이팅오늘도 화이팅오늘도 화이팅오늘도 화이팅오늘도 화이팅", profileImageURL: generateDummyProfileImageURL(size: 200)),
        People(id: UUID(), name: "장수지", statusMessage: nil, profileImageURL: generateDummyProfileImageURL(size: 200)),
        People(id: UUID(), name: "금가경", statusMessage: "과제 중", profileImageURL: generateDummyProfileImageURL(size: 200))
    ]

    var body: some View {
        List {
            // 내 프로필 섹션
            Section {
                MyProfileHeader(people: myProfile)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            // 친구 섹션
            Section {
                ForEach(friends) { person in
                    FriendRow(people: person)
                }
            } header: {
                Text("친구 \(friends.count)")
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
                    // TODO: 친구 검색 화면
                } label: {
                    Image(systemName: "magnifyingglass")
                }

                Button {
                    // TODO: 친구 추가 화면
                } label: {
                    Image(systemName: "person.badge.plus")
                }
            }
        }
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

private struct ProfileImageView: View {
    let people: People

    var body: some View {
        if let url = people.profileImageURL {
            KFImage(url)
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
}
