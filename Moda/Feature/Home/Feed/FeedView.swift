//
//  FeedView.swift
//  Moda
//
//  Created by 금가경 on 11/16/25.
//

import SwiftUI

struct FeedView: View {
    @StateObject private var store = FeedViewStore()
    @EnvironmentObject var navigator: AppNavigator

    var body: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 16
            let horizontalPadding: CGFloat = 16
            let itemWidth = (geometry.size.width - horizontalPadding * 2 - spacing) / 2

            ZStack {
                Color.white
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    logoSection
                    categoryFilterSection
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            BannerCarouselView()
                                .padding(.top, 8)

                            ProductGridView(
                                products: store.state.displayProducts,
                                itemWidth: itemWidth,
                                spacing: spacing,
                                horizontalPadding: horizontalPadding,
                                currentLocation: store.state.currentLocation,
                                isLoading: store.state.isLoading && store.state.products.isEmpty,
                                emptyMessage: store.state.isSearching ? "검색 결과가 없습니다." : "게시글이 없습니다.",
                                onLikeTapped: { postId in
                                    store.send(.toggleLike(postId))
                                },
                                onProductTapped: { postId in
                                    navigator.push(.productDetail(postId: postId))
                                },
                                onLoadMore: {
                                    if !store.state.isSearching {
                                        store.send(.loadMore)
                                    }
                                }
                            )

                            if store.state.isLoading && !store.state.products.isEmpty {
                                ProgressView()
                                    .padding()
                            }
                        }
                        .padding(.bottom, 100)
                    }
                    .refreshable {
                        store.send(.refresh)
                    }
                }
                uploadButton
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .onDisappear {
            store.send(.onDisappear)
        }
        .onReceive(NotificationCenter.default.publisher(for: AppNotification.postDeleted)) { _ in
            store.send(.refresh)
        }
        .onReceive(NotificationCenter.default.publisher(for: AppNotification.postLikeUpdated)) { notification in
            if let userInfo = notification.userInfo,
               let postId = userInfo["postId"] as? String,
               let isLiked = userInfo["isLiked"] as? Bool,
               let likeCount = userInfo["likeCount"] as? Int {
                store.send(.updateLikeFromExternal(postId: postId, isLiked: isLiked, likeCount: likeCount))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: AppNotification.postPaymentCompleted)) { _ in
            store.send(.refresh)
        }
        .onReceive(NotificationCenter.default.publisher(for: AppNotification.postUpdated)) { _ in
            store.send(.refresh)
        }
    }

    private var logoSection: some View {
        HStack(spacing: 8) {
            HStack(spacing: 0) {
                Image("AppIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40)

                Text("모다")
                    .Logo()
                    .offset(x: -4)
            }

            searchBar
        }
        .padding(.horizontal, 16)
    }

    private var searchBar: some View {
        SearchBarView(
            text: Binding(
                get: { store.state.searchText },
                set: { store.send(.search($0)) }
            ),
            placeholder: "게시글 검색",
            onClear: {
                store.send(.clearSearch)
            }
        )
    }

    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(store.state.categories, id: \.self) { category in
                    CategoryChip(
                        title: category,
                        isSelected: store.state.selectedCategory == category
                    ) {
                        store.send(.selectCategory(category))
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var uploadButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    navigator.push(.productUpload(editMode: false, postId: nil))
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("글쓰기")
                            .H2()
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color.blue1)
                    )
                }
                .padding(.trailing, 16)
                .padding(.bottom, 70)
            }
        }
    }
}

#Preview {
    FeedView()
        .environmentObject(AppNavigator.shared)
}
