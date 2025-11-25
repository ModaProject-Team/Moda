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
    @State private var selectedTab: Int = 0
    @State private var dominantColor: Color = .gray
    @State private var currentImageIndex: Int = 0

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
                    .ignoresSafeArea(edges: .top)
            }
        }
        .navigationBarHidden(true)
        .overlay(alignment: .top) {
            // Gradient + Header
            if store.state.post != nil {
                ZStack(alignment: .top) {
                    // Gradient background
                    LinearGradient(
                        colors: [.black.opacity(0.5), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 120)
                    .ignoresSafeArea()

                    HStack {
                        Button {
                            navigator.pop()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }

                        Spacer()

                        if store.state.isMyPost {
                            Button {
                                store.send(.showActionSheet)
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                }
            }
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
        GeometryReader { geometry in
            VStack {
                ScrollView {
                    VStack(spacing: 0) {
                        ZStack(alignment: .bottom) {
                            if !post.files.isEmpty {
                                TabView(selection: $currentImageIndex) {
                                    ForEach(Array(post.files.enumerated()), id: \.offset) { index, imageURL in
                                        KFImage(URL(string: "\(NetworkConfig.baseURL)/v1\(imageURL)"))
                                            .requestModifier(KFHeaders.modifier)
                                            .onSuccess { result in
                                                extractColor(from: result.image)
                                            }
                                            .placeholder {
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.3))
                                            }
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: geometry.size.width, height: geometry.size.height * 0.6)
                                            .clipped()
                                            .tag(index)
                                    }
                                }
                                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                                .frame(height: geometry.size.height * 0.4)
                                
                                if post.files.count > 1 {
                                    HStack(spacing: 6) {
                                        ForEach(0..<post.files.count, id: \.self) { index in
                                            Circle()
                                                .fill(currentImageIndex == index ? Color.white : Color.white.opacity(0.5))
                                                .frame(width: 6, height: 6)
                                        }
                                    }
                                    .padding(.bottom, 16)
                                }
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: geometry.size.height * 0.6)
                                    .overlay {
                                        Image(systemName: "photo")
                                            .font(.system(size: 60))
                                            .foregroundColor(.gray)
                                    }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 0) {

                            Text(post.title)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .multilineTextAlignment(.leading)
                                .padding(.vertical, 16)
                            
                                if let price = post.price, price > 0 {
                                    Text("\(price.formatted())원")
                                        .H2()
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black)
                                        .padding(.bottom, 20)
                                } else {
                                    Text("나눔")
                                        .H2()
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black)
                                        .padding(.bottom, 20)
                                }
                            
                            
                            VStack(spacing: 0) {
                                HStack(spacing: 0) {
                                    tabButton(title: "상세 정보", index: 0)
                                        .frame(maxWidth: .infinity)
                                    tabButton(title: "거래 장소", index: 1)
                                        .frame(maxWidth: .infinity)
                                }
                                .padding(.bottom, 12)
                                
                                // Tab Indicator
                                GeometryReader { tabGeometry in
                                    Rectangle()
                                        .fill(Color.black)
                                        .frame(width: tabGeometry.size.width / 2, height: 2)
                                        .offset(x: selectedTab == 0 ? 0 : tabGeometry.size.width / 2)
                                        .animation(.easeInOut(duration: 0.2), value: selectedTab)
                                }
                                .frame(height: 2)
                            }
                            .padding(.bottom, 16)
                            
                            if selectedTab == 0 {
                                productInfoTab(post: post)
                            } else {
                                tradeLocationTab(post: post)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100)
                    }
                }
                .scrollIndicators(.hidden)
                Spacer()
                floatingActionBar(post: post)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 8)
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Tab Button
    private func tabButton(title: String, index: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = index
            }
        } label: {
            Text(title)
                .font(.subheadline)
                .fontWeight(selectedTab == index ? .semibold : .regular)
                .foregroundColor(selectedTab == index ? .black : .gray)
        }
    }

    // MARK: - Product Info Tab
    private func productInfoTab(post: PostResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {

            if let content = post.content, !content.isEmpty {
                Text(content)
                    .font(.body)
                    .foregroundColor(.black.opacity(0.8))
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
            } else {
                Text("상품 설명이 없습니다.")
                    .font(.body)
                    .foregroundColor(.gray)
            }
            
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.pink1)
                    Text("\(store.state.likeCount)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Text(store.formattedDate(from: post.createdAt))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Trade Location Tab
    private func tradeLocationTab(post: PostResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if let locationName = post.value1, !locationName.isEmpty,
               let geolocation = post.geolocation {
                Text(locationName)
                    .font(.subheadline)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)

                Map(initialPosition: .region(
                    MKCoordinateRegion(
                        center: CLLocationCoordinate2D(
                            latitude: geolocation.latitude,
                            longitude: geolocation.longitude
                        ),
                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                    )
                )) {
                    Annotation("", coordinate: CLLocationCoordinate2D(
                        latitude: geolocation.latitude,
                        longitude: geolocation.longitude
                    )) {
                        Image("pin")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                    }
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                Text("거래 장소 정보가 없습니다.")
                    .font(.body)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Floating Action Bar
    private func floatingActionBar(post: PostResponse) -> some View {
        HStack(spacing: 16) {
            Button {
                // Navigate to seller profile
            } label: {
                if let profileImage = post.creator.profileImage, !profileImage.isEmpty {
                    KFImage(URL(string: "\(NetworkConfig.baseURL)/v1\(profileImage)"))
                        .requestModifier(KFHeaders.modifier)
                        .placeholder {
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
            }

            Text("|")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.3))
            
            Button {
                // TODO: 결제 기능 구현
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 14))
                }
                .foregroundColor(.white)
            }

            Button {
                // Navigate to chat
            } label: {
                Image(systemName: "message.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            
            Button {
                store.send(.toggleLike)
            } label: {
                Image(systemName: store.state.isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 16))
                    .foregroundColor(store.state.isLiked ? .pink1 : .white)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 14)
        .background(
            Capsule()
                .fill(Color.blue1)
        )
    }

    // MARK: - Extract Color
    private func extractColor(from image: KFCrossPlatformImage) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let cgImage = image.cgImage else { return }

            let width = 1
            let height = 1
            let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

            guard let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: bitmapInfo
            ) else { return }

            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

            guard let data = context.data else { return }
            let pointer = data.bindMemory(to: UInt8.self, capacity: 4)

            let r = CGFloat(pointer[0]) / 255.0
            let g = CGFloat(pointer[1]) / 255.0
            let b = CGFloat(pointer[2]) / 255.0

            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.dominantColor = Color(red: r, green: g, blue: b)
                }
            }
        }
    }

}

#Preview {
    NavigationStack {
        ProductDetailView(postId: "test")
            .environmentObject(AppNavigator.shared)
    }
}
