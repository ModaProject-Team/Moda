//
//  MapPostCardView.swift
//  Moda
//
//  Created by Suji Jang on 11/17/25.
//

import SwiftUI
import Kingfisher

struct MapPostCardView: View {
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
            KFImage(URL(string: "\(NetworkConfig.baseURL)/v1\(post.media)"))
                .requestModifier(KFHeaders.modifier)
                .placeholder {
                    Image(systemName: "photo")
                        .foregroundColor(.gray3)
                }
                .cacheOriginalImage()
                .fade(duration: 0.2)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(post.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.gray1)
                    .lineLimit(1)

                Text("\(post.price.formatted())원")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue1)

                HStack(spacing: 4) {
                    KFImage(URL(string: "\(NetworkConfig.baseURL)/v1\(post.profileImage)"))
                        .requestModifier(KFHeaders.modifier)
                        .placeholder {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.gray3)
                        }
                        .cacheOriginalImage()
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 16, height: 16)
                        .clipShape(Circle())

                    Text(post.nickname)
                        .font(.system(size: 12))
                        .foregroundColor(.gray2)
                }
            }

            Spacer()

            Button {
                isLiked.toggle()
                onLikeTapped(post.id, isLiked)
            } label: {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .foregroundColor(isLiked ? .pink1 : .gray3)
                    .font(.system(size: 20))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: -2)
        .padding(.horizontal, 16)
        .padding(.bottom, 60)
        .contentShape(Rectangle())
        .onTapGesture {
            onTapped()
        }
    }
}
