//
//  ClusterPostListItemView.swift
//  Moda
//
//  Created by Suji Jang on 11/18/25.
//

import SwiftUI
import Kingfisher

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
                KFImage(URL(string: "\(NetworkConfig.baseURL)/v1\(post.media)"))
                    .requestModifier(KFHeaders.modifier)
                    .placeholder {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                    }
                    .cacheOriginalImage()
                    .fade(duration: 0.2)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                
                Text(post.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .lineLimit(2)
                
                Text("\(post.price)원")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.blue1)

                Spacer()
                
                HStack(spacing: 6) {
                    if !post.profileImage.isEmpty {
                        KFImage(URL(string: "\(NetworkConfig.baseURL)/v1\(post.profileImage)"))
                            .requestModifier(KFHeaders.modifier)
                            .placeholder {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                            }
                            .cacheOriginalImage()
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 20, height: 20)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 20, height: 20)
                    }

                    Text(post.nickname)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Button {
                isLiked.toggle()
                onLikeTapped(post.id, isLiked)
            } label: {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 20))
                    .foregroundColor(isLiked ? .pink1 : .gray)
            }
            .padding(.trailing, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .contentShape(Rectangle())
        .onTapGesture {
            onTapped()
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
            price: 50000
        )
    )
}
