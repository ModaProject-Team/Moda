//
//  ProductDetailView.swift
//  Moda
//
//  Created by Suji Jang on 11/22/24.
//

import SwiftUI
import Kingfisher
import MapKit

extension Notification.Name {
    static let postDeleted = Notification.Name("postDeleted")
    static let postLikeUpdated = Notification.Name("postLikeUpdated")
}

struct ProductDetailView: View {

    let postId: String
    @StateObject private var store: ProductDetailStore
    @EnvironmentObject var navigator: AppNavigator

    init(postId: String) {
        self.postId = postId
        self._store = StateObject(wrappedValue: ProductDetailStore(postId: postId))
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            if store.state.isLoading {
                ProgressView()
            } else if let error = store.state.errorMessage {
                errorView(error: error)
            } else if let post = store.state.post {
                contentView(post: post)
            }
        }
        .navigationBarHidden(true)
        .overlay(alignment: .top) {
            headerView
        }
        .task {
            store.send(.loadPost)
        }
        .confirmationDialog("", isPresented: Binding(
            get: { store.state.showActionSheet },
            set: { if !$0 { store.send(.dismissActionSheet) } }
        ), titleVisibility: .hidden) {
            Button("게시글 수정") {
                // TODO: 수정 화면으로 이동
            }
            Button("삭제", role: .destructive) {
                store.send(.showDeleteAlert)
            }
            Button("취소", role: .cancel) { }
        }
        .alert("게시글 삭제", isPresented: Binding(
            get: { store.state.showDeleteAlert },
            set: { if !$0 { store.send(.dismissDeleteAlert) } }
        )) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                store.send(.deletePost)
            }
        } message: {
            Text("이 게시글을 삭제하시겠습니까?\n삭제된 게시글은 복구할 수 없습니다.")
        }
        .disabled(store.state.isDeleting)
        .overlay {
            if store.state.isDeleting {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(.white)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .postDeleted)) { _ in
            navigator.popToRoot()
        }
    }

    // MARK: - Error View
    private func errorView(error: String) -> some View {
        VStack(spacing: 16) {
            Text("오류가 발생했습니다")
                .H2()
                .foregroundColor(.gray1)
            Text(error)
                .Body2()
                .foregroundColor(.gray2)
            Button("다시 시도") {
                store.send(.loadPost)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.blue1)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }

    // MARK: - Content View
    private func contentView(post: PostResponse) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 이미지 섹션
                if !post.files.isEmpty {
                    TabView {
                        ForEach(post.files, id: \.self) { imageURL in
                            KFImage(URL(string: "\(NetworkConfig.baseURL)/v1\(imageURL)"))
                                .requestModifier(KFHeaders.modifier)
                                .placeholder {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                }
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .frame(height: 300)
                }

                VStack(alignment: .leading, spacing: 16) {
                    // 작성자 정보
                    authorSection(post: post)

                    Divider()

                    // 제목
                    Text(post.title)
                        .H1()
                        .foregroundColor(.gray1)

                    // 가격
                    priceSection(post: post)

                    // 내용
                    if let content = post.content, !content.isEmpty {
                        Text(content)
                            .Body1()
                            .foregroundColor(.gray1)
                            .padding(.top, 8)
                    }

                    // 거래 희망 장소
                    if let locationName = post.value1, !locationName.isEmpty,
                       let geolocation = post.geolocation {
                        TradeLocationView(
                            title: locationName,
                            coordinate: CLLocationCoordinate2D(
                                latitude: geolocation.latitude,
                                longitude: geolocation.longitude
                            ),
                            onMapTap: {
                                // TODO: 지도 상세 화면으로 이동
                            }
                        )
                        .padding(.top, 16)
                    }

                    // 좋아요 수 및 게시일
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.pink1)
                            Text("\(store.state.likeCount)")
                                .Body2()
                                .foregroundColor(.gray2)
                        }

                        Text(store.formattedDate(from: post.createdAt))
                            .Body2()
                            .foregroundColor(.gray2)
                    }
                    .padding(.top, 12)

                    // 하단 액션 버튼
                    actionButtons
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Author Section
    private func authorSection(post: PostResponse) -> some View {
        HStack(spacing: 12) {
            if let profileImage = post.creator.profileImage, !profileImage.isEmpty {
                KFImage(URL(string: "\(NetworkConfig.baseURL)/v1\(profileImage)"))
                    .requestModifier(KFHeaders.modifier)
                    .placeholder {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
            }

            Text(post.creator.nick)
                .Body1()
                .foregroundColor(.gray1)

            Spacer()
        }
        .padding(.vertical, 12)
    }

    // MARK: - Price Section
    private func priceSection(post: PostResponse) -> some View {
        Group {
            if let price = post.price, price > 0 {
                Text("\(price.formatted())원")
                    .H2()
                    .foregroundColor(.black)
            } else {
                Text("나눔")
                    .H2()
                    .foregroundColor(.black)
            }
        }
    }

    // MARK: - Action Buttons
    @ViewBuilder
    private var actionButtons: some View {
        if store.state.isMyPost {
            // 내 게시글인 경우
            EmptyView()
        } else {
            // 다른 사람 게시글인 경우
            HStack(spacing: 12) {
                // 좋아요 버튼
                Button {
                    store.send(.toggleLike)
                } label: {
                    Image(systemName: store.state.isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(store.state.isLiked ? .pink1 : .gray2)
                        .frame(width: 56, height: 56)
                        .background(Color.gray5)
                        .cornerRadius(12)
                }

                // 채팅하기 버튼
                Button {
                    // TODO: 채팅방으로 이동
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 16))
                        Text("채팅하기")
                            .H2()
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue1)
                    .cornerRadius(12)
                }
            }
            .padding(.top, 24)
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button {
                navigator.pop()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18))
                    .foregroundColor(.gray1)
            }

            Spacer()

            Text("상품 상세")
                .H1()
                .foregroundColor(.gray1)

            Spacer()

            if store.state.isMyPost {
                Button {
                    store.send(.showActionSheet)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18))
                        .foregroundColor(.gray1)
                }
            } else {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18))
                    .foregroundColor(.clear)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(postId: "test")
            .environmentObject(AppNavigator.shared)
    }
}
