//
//  ClusterPostListItemView.swift
//  Moda
//
//  Created by Suji Jang on 11/18/25.
//

import SwiftUI

struct ClusterPostListItemView: View {
    let post: PostAnnotation
    let onLikeTapped: (String, Bool) -> Void
    let onTapped: () -> Void
    @State private var isLiked: Bool

    init(post: PostAnnotation, onLikeTapped: @escaping (String, Bool) -> Void = { _, _ in }, onTapped: @escaping () -> Void = {}) {
        self.post = post
        self.onLikeTapped = onLikeTapped
        self.onTapped = onTapped
        self._isLiked = State(initialValue: post.like)
    }

    var body: some View {
        HStack(spacing: 12) {
            if !post.media.isEmpty {
                MediaImageView(
                    mediaURL: post.media,
                    contentMode: .fill,
                    placeholder: {
                        AnyView(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray5)
                        )
                    }
                )
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray5)
                    .frame(width: 80, height: 80)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(post.title)
                    .H2()
                    .foregroundColor(.gray1)
                    .lineLimit(2)

                Text("\(post.price.formatted())원")
                    .Body1()
                    .foregroundColor(.blue1)

                Spacer()

                HStack(spacing: 6) {
                    if !post.profileImage.isEmpty {
                        CachedImageView(
                            url: URL(string: "\(NetworkConfig.baseURL)/v1\(post.profileImage)"),
                            targetSize: CGSize(width: 18, height: 18),
                            contentMode: .fill,
                            placeholder: {
                                AnyView(
                                    Circle()
                                        .fill(Color.gray5)
                                )
                            }
                        )
                        .cacheOriginalImage()
                        .frame(width: 18, height: 18)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray5)
                            .frame(width: 18, height: 18)
                    }

                    Text(post.nickname)
                        .Body2()
                        .foregroundColor(.gray2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                isLiked.toggle()
                onLikeTapped(post.id, isLiked)
            } label: {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 18))
                    .foregroundColor(isLiked ? .pink1 : .gray3)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .contentShape(Rectangle())
        .onTapGesture {
            onTapped()
        }
        .onChange(of: post.like) { _, newValue in
            isLiked = newValue
        }
    }
}

#Preview {
    ClusterPostListItemView(
        post: PostAnnotation(
            id: "1",
            title: "테스트 게시물",
            media: "mac",
            like: false,
            profileImage: "mac",
            nickname: "닉네임",
            latitude: 37.5,
            longitude: 127.0,
            price: 50000,
            creatorId: "test-user-id"
        )
    )
}
