//
//  ClusterSheetView.swift
//  Moda
//
//  Created by Suji Jang on 11/18/25.
//

import SwiftUI

struct ClusterSheetView: View {
    let posts: [PostAnnotation]
    let onDismiss: () -> Void
    let onLikeTapped: (String, Bool) -> Void
    let onPostTapped: (String) -> Void

    init(posts: [PostAnnotation], onDismiss: @escaping () -> Void, onLikeTapped: @escaping (String, Bool) -> Void = { _, _ in }, onPostTapped: @escaping (String) -> Void = { _ in }) {
        self.posts = posts
        self.onDismiss = onDismiss
        self.onLikeTapped = onLikeTapped
        self.onPostTapped = onPostTapped
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(posts) { post in
                        ClusterPostListItemView(
                            post: post,
                            onLikeTapped: onLikeTapped,
                            onTapped: {
                                onPostTapped(post.id)
                            }
                        )

                        if post.id != posts.last?.id {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .presentationDetents([.height(300), .large])
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.enabled)
    }
}

#Preview {
    ClusterSheetView(
        posts: [
            PostAnnotation(
                id: "1",
                title: "테스트 게시물 1",
                media: "mac",
                like: false,
                profileImage: "mac",
                nickname: "닉네임1",
                latitude: 37.5,
                longitude: 127.0,
                price: 50000
            ),
            PostAnnotation(
                id: "2",
                title: "테스트 게시물 2",
                media: "mac",
                like: true,
                profileImage: "mac",
                nickname: "닉네임2",
                latitude: 37.5,
                longitude: 127.0,
                price: 30000
            )
        ],
        onDismiss: {}
    )
}
