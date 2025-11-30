//
//  ProfileDetailView.swift
//  Moda
//
//  Created by hyunMac on 11/17/25.
//

import SwiftUI
import Observation
import Combine

struct ProfileDetailView: View {
    @State private var store: ProfileDetailStore
    @EnvironmentObject var navigator: AppNavigator

    init(people: People, isCurrentUser: Bool) {
        let initial = ProfileDetailState(
            userId: people.id,
            isCurrentUser: isCurrentUser,
            nickname: people.name,
            profileImageURL: people.profileImageURL
        )
        _store = State(initialValue: ProfileDetailStore(initial: initial))
    }

    var body: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 12
            let horizontalPadding: CGFloat = 16
            let itemWidth = (geometry.size.width - horizontalPadding * 2 - spacing) / 2

            ZStack {
                Color.white.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        header

                        if store.state.isCurrentUser {
                            segment
                        }

                        ProductGridView(
                            products: store.state.currentList,
                            itemWidth: itemWidth,
                            spacing: spacing,
                            horizontalPadding: horizontalPadding,
                            currentLocation: nil,
                            isLoading: store.state.isLoading,
                            emptyMessage: store.state.isCurrentUser && store.state.selectedTab == .likeItems ? "찜한 물건이 없어요" : "등록된 물건이 없어요",
                            onLikeTapped: { postId in
                                store.send(.toggleLike(postId))
                            },
                            onProductTapped: { postId in
                                navigator.push(.productDetail(postId: postId))
                            },
                            onLoadMore: {
                                store.send(.loadMore)
                            }
                        )
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 80)
                }
                .refreshable {
                    store.send(.refresh)
                }

                if store.state.isLoading && store.state.currentList.isEmpty {
                    ProgressView()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    navigator.pop()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.gray1)
                }
            }
        }
        .enableSwipeBack()
        .overlay(alignment: .bottomTrailing) {
            if store.state.isCurrentUser {
                FloatingUploadButton(title: "물건 올리기") {
                    navigator.push(.productUpload(editMode: false, postId: nil))
                }
                .padding(.trailing, 16)
                .padding(.bottom, 24)
            }
        }
        .task { store.send(.onAppear) }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Group {
                if let url = store.state.profileImageURL {
                    CachedImageView(
                        url: url,
                        targetSize: CGSize(width: 72, height: 72),
                        contentMode: .fill,
                        placeholder: {
                            AnyView(
                                Circle().fill(Color.gray3)
                            )
                        }
                    )
                    .cacheOriginalImage()
                    .fade(duration: 0.2)
                    .frame(width: 72, height: 72)
                    .clipShape(Circle())
                } else {
                    ZStack {
                        Circle().fill(Color.gray3)
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    }
                    .frame(width: 72, height: 72)
                }
            }

            Text(store.state.nickname)
                .H2()
                .foregroundColor(.gray1)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var segment: some View {
        Picker("", selection: Binding(
            get: { store.state.selectedTab },
            set: { store.send(.selectTab($0)) }
        )) {
            ForEach(ProfileTab.allCases) { tab in
                Text(tab.title).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
    }

}

private struct FloatingUploadButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Text(title)
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
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    NavigationStack {
        VStack(spacing: 12) {
            ProfileDetailView(
                people: People(id: "me", name: "나의 닉네임", statusMessage: "상태메시지", profileImageURL: nil),
                isCurrentUser: true
            )
            .navigationTitle("프로필")
        }
    }
}
