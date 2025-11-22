//
//  FeedView.swift
//  Moda
//
//  Created by 금가경 on 11/16/25.
//

import SwiftUI

// MARK: - View
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

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        logoSection
                        categoryFilterSection
                        userInfoCard
                        productSectionView(itemWidth: itemWidth, spacing: spacing, horizontalPadding: horizontalPadding)

                        if store.state.isLoading && !store.state.products.isEmpty {
                            ProgressView()
                                .padding()
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
                .refreshable {
                    store.send(.refresh)
                }

                uploadButton
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }

    private var logoSection: some View {
        HStack {
            Image("AppIcon")
                .resizable()
                .scaledToFit()
                .frame(height: 48)

            Spacer()

            Button {
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20))
                    .foregroundColor(.gray1)
            }
        }
        .padding(.horizontal, 16)
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

    private var userInfoCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.gray3)
                    .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text(store.state.userName)
                        .H1()
                        .foregroundColor(.gray1)

                    Text("프로필")
                        .Body1()
                        .foregroundColor(.gray2)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                QuickActionButton(icon: "arrow.up.circle.fill", title: "올리기") {
                    navigator.push(.productUpload)
                }
                QuickActionButton(icon: "heart.fill", title: "찜 목록") {
                }
                QuickActionButton(icon: "clock.fill", title: "거래내역") {
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.gray5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.gray4, lineWidth: 0.5)
        )
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func productSectionView(itemWidth: CGFloat, spacing: CGFloat, horizontalPadding: CGFloat) -> some View {
        if store.state.products.isEmpty && store.state.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, 50)
        } else if store.state.products.isEmpty {
            Text("게시글이 없습니다.")
                .Body1()
                .foregroundColor(.gray2)
                .frame(maxWidth: .infinity)
                .padding(.top, 50)
        } else {
            HStack(alignment: .top, spacing: spacing) {
                // 왼쪽 열
                VStack(spacing: 12) {
                    ForEach(Array(store.state.products.enumerated().filter { $0.offset % 2 == 0 }), id: \.element.id) { index, product in
                        PostCardView(
                            product: product,
                            itemWidth: itemWidth,
                            currentLocation: store.state.currentLocation,
                            onLikeTapped: {
                                store.send(.toggleLike(product.id))
                            }
                        )
                        .onAppear {
                            if index >= store.state.products.count - 4 {
                                store.send(.loadMore)
                            }
                        }
                    }
                }
                .frame(width: itemWidth)

                // 오른쪽 열
                VStack(spacing: 12) {
                    ForEach(Array(store.state.products.enumerated().filter { $0.offset % 2 == 1 }), id: \.element.id) { index, product in
                        PostCardView(
                            product: product,
                            itemWidth: itemWidth,
                            currentLocation: store.state.currentLocation,
                            onLikeTapped: {
                                store.send(.toggleLike(product.id))
                            }
                        )
                        .onAppear {
                            if index >= store.state.products.count - 4 {
                                store.send(.loadMore)
                            }
                        }
                    }
                }
                .frame(width: itemWidth)
            }
            .padding(.horizontal, horizontalPadding)
        }
    }

    private var uploadButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    navigator.push(.productUpload)
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
                .padding(.trailing, 20)
                .padding(.bottom, 80)
            }
        }
    }
}

#Preview {
    FeedView()
        .environmentObject(AppNavigator.shared)
}
