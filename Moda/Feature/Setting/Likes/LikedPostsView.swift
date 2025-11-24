//
//  LikedPostsView.swift
//  Moda
//
//  Created by Suji Jang on 11/24/24.
//

import SwiftUI
import Kingfisher

struct LikedPostsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = LikedPostsStore()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                if store.state.isLoading && store.state.posts.isEmpty {
                    ProgressView()
                } else if store.state.posts.isEmpty {
                    Text("찜한 물건이 없어요")
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(store.state.posts.enumerated()), id: \.element.id) { index, post in
                                LikedPostItemView(
                                    post: post,
                                    onLikeTapped: { store.send(.toggleLike(post.id)) },
                                    onTapped: { store.send(.postTapped(post.id)) }
                                )

                                if index < store.state.posts.count - 1 {
                                    Divider()
                                        .padding(.leading, 108)
                                }

                                if index >= store.state.posts.count - 4 {
                                    Color.clear
                                        .onAppear {
                                            store.send(.loadMore)
                                        }
                                }
                            }
                        }
                    }
                    .refreshable {
                        store.send(.refresh)
                    }
                }
            }
            .navigationTitle("좋아요")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .task {
            store.send(.onAppear)
        }
    }
}

private struct LikedPostItemView: View {
    let post: LikedPost
    let onLikeTapped: () -> Void
    let onTapped: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if let url = post.mediaURL {
                KFImage(url)
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
                    if let url = post.profileImageURL {
                        KFImage(url)
                            .requestModifier(KFHeaders.modifier)
                            .placeholder {
                                Circle().fill(Color.gray.opacity(0.3))
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

            // 좋아요 버튼
            Button {
                onLikeTapped()
            } label: {
                Image(systemName: post.isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 20))
                    .foregroundColor(post.isLiked ? .pink1 : .gray)
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
    LikedPostsView()
}
