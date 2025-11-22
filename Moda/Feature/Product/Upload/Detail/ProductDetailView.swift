//
//  ProductDetailView.swift
//  Moda
//
//  Created by Claude on 11/22/24.
//

import SwiftUI
import Kingfisher

struct ProductDetailView: View {

    let postId: String
    @EnvironmentObject var navigator: AppNavigator
    @State private var post: PostResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?

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

                            if let price = post.price {
                                if price == 0 {
                                    Text("나눔")
                                        .H2()
                                        .foregroundColor(.blue1)
                                } else {
                                    Text("\(price.formatted())원")
                                        .H2()
                                        .foregroundColor(.blue1)
                                }
                            }
                            
                            if let content = post.content, !content.isEmpty {
                                Text(content)
                                    .Body1()
                                    .foregroundColor(.gray1)
                                    .padding(.top, 8)
                            }

                            if let locationName = post.value1, !locationName.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(.gray2)
                                    Text(locationName)
                                        .Body2()
                                        .foregroundColor(.gray2)
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
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

                Button {
                    // TODO: 더보기 메뉴
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18))
                        .foregroundColor(.gray1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
        }
        .task {
            await loadPost()
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
}

#Preview {
    NavigationStack {
        ProductDetailView(postId: "test")
            .environmentObject(AppNavigator.shared)
    }
}
