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

    var body: some View {
        List {
            Section {
                MyProfileHeader(people: myProfile)
            }
        }
        .listStyle(.plain)
        .navigationTitle("친구")
        .navigationBarTitleDisplayMode(.large)
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
                    .foregroundStyle(.primary)

                if let msg = people.statusMessage, !msg.isEmpty {
                    Text(msg)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
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
