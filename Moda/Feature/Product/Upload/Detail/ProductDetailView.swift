//
//  ProductDetailView.swift
//  Moda
//
//  Created by Claude on 11/22/24.
//

import SwiftUI
import Kingfisher
import MapKit

extension Notification.Name {
    static let postDeleted = Notification.Name("postDeleted")
}

struct ProductDetailView: View {

    let postId: String
    @EnvironmentObject var navigator: AppNavigator
    @State private var post: PostResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    @State private var showActionSheet = false

    private var isMyPost: Bool {
        guard let post = post else { return false }
        let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? ""
        return post.creator.userId == currentUserId
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            if isLoading {
                ProgressView()
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Text("오류가 발생했습니다")
                        .H2()
                        .foregroundColor(.gray1)
                    Text(error)
                        .Body2()
                        .foregroundColor(.gray2)
                    Button("다시 시도") {
                        Task {
                            await loadPost()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue1)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            } else if let post = post {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
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

                            Divider()

                            Text(post.title)
                                .H1()
                                .foregroundColor(.gray1)

                            if let price = post.price, price > 0 {
                                Text("\(price.formatted())원")
                                    .H2()
                                    .foregroundColor(.black)
                            } else {
                                Text("나눔")
                                    .H2()
                                    .foregroundColor(.black)
                            }
                            
                            if let content = post.content, !content.isEmpty {
                                Text(content)
                                    .Body1()
                                    .foregroundColor(.gray1)
                                    .padding(.top, 8)
                            }

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

                            HStack(spacing: 16) {
                                HStack(spacing: 4) {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.pink1)
                                    Text("\(post.likes.count)")
                                        .Body2()
                                        .foregroundColor(.gray2)
                                }

                                Text(formattedDate(from: post.createdAt))
                                    .Body2()
                                    .foregroundColor(.gray2)
                            }
                            .padding(.top, 12)

                            // 하단 액션 버튼
                            if isMyPost {
                                // 내 게시글인 경우
                            } else {
                                // 다른 사람 게시글인 경우
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
                                .padding(.top, 24)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .overlay(alignment: .top) {
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

                if isMyPost {
                    Button {
                        showActionSheet = true
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
        .task {
            await loadPost()
        }
        .confirmationDialog("", isPresented: $showActionSheet, titleVisibility: .hidden) {
            Button("게시글 수정") {
                // TODO: 수정 화면으로 이동
            }
            Button("삭제", role: .destructive) {
                showDeleteAlert = true
            }
            Button("취소", role: .cancel) { }
        }
        .alert("게시글 삭제", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                Task {
                    await deletePost()
                }
            }
        } message: {
            Text("이 게시글을 삭제하시겠습니까?\n삭제된 게시글은 복구할 수 없습니다.")
        }
        .disabled(isDeleting)
        .overlay {
            if isDeleting {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(.white)
            }
        }
    }

    private func loadPost() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await PostAPI.shared.getPost(postId: postId)
            post = response
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    private func deletePost() async {
        isDeleting = true

        do {
            try await PostAPI.shared.deletePost(postId: postId)
            isDeleting = false
            NotificationCenter.default.post(name: .postDeleted, object: nil)
            navigator.popToRoot()
        } catch {
            isDeleting = false
            print("게시글 삭제 실패: \(error.localizedDescription)")
        }
    }

    private func formattedDate(from createdAt: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var parsedDate: Date?

        if let date = isoFormatter.date(from: createdAt) {
            parsedDate = date
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            parsedDate = dateFormatter.date(from: createdAt)
        }

        guard let date = parsedDate else {
            return createdAt
        }

        let now = Date()
        let interval = now.timeIntervalSince(date)

        if interval < 60 {
            return "방금 전"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)분 전"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)시간 전"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)일 전"
        } else {
            let outputFormatter = DateFormatter()
            outputFormatter.locale = Locale(identifier: "ko_KR")
            outputFormatter.dateFormat = "MM.dd"
            return outputFormatter.string(from: date)
        }
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(postId: "test")
            .environmentObject(AppNavigator.shared)
    }
}
