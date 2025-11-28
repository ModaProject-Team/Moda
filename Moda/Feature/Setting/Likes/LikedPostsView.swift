//
//  LikedPostsView.swift
//  Moda
//
//  Created by Suji Jang on 11/24/24.
//

import SwiftUI
import Kingfisher

struct LikedPostsView: View {
    @EnvironmentObject var navigator: AppNavigator
    @State private var store = LikedPostsStore()

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            if store.state.isLoading && store.state.posts.isEmpty {
                shimmerList
            } else if store.state.posts.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(store.state.posts.enumerated()), id: \.element.id) { index, post in
                            LikedPostItemView(
                                post: post,
                                onLikeTapped: { store.send(.toggleLike(post.id)) },
                                onTapped: { navigator.push(.productDetail(postId: post.id)) }
                            )
                            .onAppear {
                                if index >= store.state.posts.count - 4 {
                                    store.send(.loadMore)
                                }
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
        .navigationTitle("찜 목록")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    navigator.pop()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18))
                        .foregroundColor(.gray1)
                }
            }
        }
        .task {
            store.send(.onAppear)
        }
    }

    private var shimmerList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(0..<5, id: \.self) { _ in
                    LikedPostShimmerView()
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 48))
                .foregroundColor(.gray3)

            Text("찜한 게시글이 없습니다")
                .H2()
                .foregroundColor(.gray2)

            Text("마음에 드는 물건을 찜해보세요")
                .Body2()
                .foregroundColor(.gray3)
        }
    }
}

private struct LikedPostItemView: View {
    let post: LikedPost
    let onLikeTapped: () -> Void
    let onTapped: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                if let mediaPath = post.mediaPath {
                    MediaImageView(
                        mediaURL: mediaPath,
                        contentMode: .fill,
                        placeholder: {
                            AnyView(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.gray5)
                            )
                        }
                    )
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    // 동영상인 경우 재생 아이콘 표시
                    if mediaPath.isVideoFile {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2)
                    }
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.gray5)
                        .frame(width: 80, height: 80)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(post.title)
                    .Body1()
                    .foregroundColor(.gray1)
                    .lineLimit(2)

                Text("\(post.price)원")
                    .H2()
                    .foregroundColor(.gray1)

                Spacer()

                HStack(spacing: 6) {
                    if let url = post.profileImageURL {
                        KFImage(url)
                            .requestModifier(KFHeaders.modifier)
                            .placeholder {
                                Circle().fill(Color.gray3)
                            }
                            .cacheOriginalImage()
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 20, height: 20)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray3)
                            .frame(width: 20, height: 20)
                    }

                    Text(post.nickname)
                        .Body2()
                        .foregroundColor(.gray2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                onLikeTapped()
            } label: {
                Image(systemName: post.isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 20))
                    .foregroundColor(post.isLiked ? .pink1 : .gray2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .onTapGesture {
            onTapped()
        }
    }
}

private struct LikedPostShimmerView: View {
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.gray4)
                .frame(width: 80, height: 80)
                .shimmer()

            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray4)
                    .frame(height: 16)
                    .shimmer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray4)
                    .frame(width: 80, height: 16)
                    .shimmer()

                Spacer()

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.gray4)
                        .frame(width: 20, height: 20)
                        .shimmer()

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray4)
                        .frame(width: 60, height: 12)
                        .shimmer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Circle()
                .fill(Color.gray4)
                .frame(width: 24, height: 24)
                .shimmer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    LikedPostsView()
        .environmentObject(AppNavigator.shared)
}
