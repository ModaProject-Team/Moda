//
//  SettingView.swift
//  Moda
//
//  Created by Suji Jang on 11/24/25.
//

import SwiftUI
import Kingfisher

struct SettingView: View {
    @State private var store = SettingStore()
    @State private var showProfileEdit = false
    @State private var showLikedPosts = false
    @State private var showLogoutAlert = false

    var body: some View {
        ZStack {
            backgroundSection

            VStack(spacing: 0) {
                Spacer()

                profileImageSection

                Text(store.state.nickname)
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.top, 16)

                actionButtonsSection
                    .padding(.top, 32)

                Spacer()
            }
        }
        .task {
            store.send(.onAppear)
        }
        .fullScreenCover(isPresented: $showProfileEdit, onDismiss: {
            store.send(.refresh)
        }) {
            ProfileEditView()
        }
        .fullScreenCover(isPresented: $showLikedPosts) {
            LikedPostsView()
        }
        .alert("로그아웃", isPresented: $showLogoutAlert) {
            Button("취소", role: .cancel) { }
            Button("로그아웃", role: .destructive) {
                logout()
            }
        } message: {
            Text("로그아웃")
        }
    }

    private var backgroundSection: some View {
        GeometryReader { geometry in
            ZStack {
                if let url = store.state.latestPostImageURL {
                    KFImage(url)
                        .requestModifier(KFHeaders.modifier)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else {
                    Color.gray
                }

                Color.black.opacity(0.5)
            }
        }
        .ignoresSafeArea()
    }

    private var profileImageSection: some View {
        Group {
            if let url = store.state.profileImageURL {
                KFImage(url)
                    .requestModifier(KFHeaders.modifier)
                    .placeholder {
                        Circle().fill(Color.gray.opacity(0.3))
                    }
                    .cacheOriginalImage()
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
            } else {
                ZStack {
                    Circle().fill(Color.gray.opacity(0.3))
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                }
                .frame(width: 100, height: 100)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                )
            }
        }
    }

    private var actionButtonsSection: some View {
        HStack(spacing: 40) {
            Button {
                showProfileEdit = true
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "pencil")
                        .font(.system(size: 24))
                    Text("프로필 수정")
                        .font(.caption)
                }
                .foregroundColor(.white)
            }

            Button {
                showLikedPosts = true
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "heart")
                        .font(.system(size: 24))
                    Text("좋아요")
                        .font(.caption)
                }
                .foregroundColor(.white)
            }

            Button {
                showLogoutAlert = true
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 24))
                    Text("로그아웃")
                        .font(.caption)
                }
                .foregroundColor(.white)
            }
        }
    }

    private func logout() {
        TokenManager.shared.clearToken()
        UserDefaults.standard.removeObject(forKey: "userId")
        AppNavigator.shared.popToRoot()
        AppNavigator.shared.isLoggedIn = false
    }
}

#Preview {
    SettingView()
}
