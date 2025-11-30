//
//  MapPostCardView.swift
//  Moda
//
//  Created by Suji Jang on 11/17/25.
//

import SwiftUI

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
            MediaImageView(
                mediaURL: post.media,
                contentMode: .fill,
                placeholder: {
                    AnyView(
                        Image(systemName: "photo")
                            .foregroundColor(.gray3)
                    )
                }
            )
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text(post.title)
                    .H2()
                    .foregroundColor(.gray1)
                    .lineLimit(1)

                Text("\(post.price.formatted())원")
                    .Body1()
                    .foregroundColor(.blue1)

                HStack(spacing: 6) {
                    CachedImageView(
                        url: URL(string: "\(NetworkConfig.baseURL)/v1\(post.profileImage)"),
                        targetSize: CGSize(width: 18, height: 18),
                        contentMode: .fill,
                        placeholder: {
                            AnyView(
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.gray3)
                            )
                        }
                    )
                    .frame(width: 18, height: 18)
                    .clipShape(Circle())

                    Text(post.nickname)
                        .Body2()
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
                    .font(.system(size: 18))
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .padding(.horizontal, 16)
        .padding(.bottom, 60)
        .contentShape(Rectangle())
        .onTapGesture {
            onTapped()
        }
        .onChange(of: post.like) { _, newValue in
            isLiked = newValue
        }
    }
}
