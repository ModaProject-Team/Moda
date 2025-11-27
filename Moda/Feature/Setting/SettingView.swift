//
//  SettingView.swift
//  Moda
//
//  Created by Suji Jang on 11/24/25.
//

import SwiftUI
import Kingfisher

struct SettingView: View {
    @EnvironmentObject var navigator: AppNavigator
    @State private var store = SettingStore()
    @State private var showProfileEdit = false
    @State private var showLogoutAlert = false

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabHeaderView(title: "프로필")

                profileCardSection
                    .padding(.top, 16)
                    .padding(.horizontal, 16)

                actionCardsSection
                    .padding(.top, 20)
                    .padding(.horizontal, 16)

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
        .alert("로그아웃", isPresented: $showLogoutAlert) {
            Button("취소", role: .cancel) { }
            Button("로그아웃", role: .destructive) {
                logout()
            }
        } message: {
            Text("로그아웃 하시겠습니까?")
        }
    }

    private var profileCardSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                profileImageView
                    .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text(store.state.nickname)
                        .H2()
                        .foregroundColor(.gray1)

                    Text("프로필 설정")
                        .Body2()
                        .foregroundColor(.gray2)
                }

                Spacer()

                Button {
                    showProfileEdit = true
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray2)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.gray5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.gray4, lineWidth: 0.5)
        )
        .onTapGesture {
            showProfileEdit = true
        }
    }

    private var profileImageView: some View {
        Group {
            if let url = store.state.profileImageURL {
                KFImage(url)
                    .requestModifier(KFHeaders.modifier)
                    .placeholder {
                        Circle().fill(Color.gray3)
                    }
                    .cacheOriginalImage()
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle().fill(Color.gray3)
                    Image(systemName: "person.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                }
                .frame(width: 48, height: 48)
            }
        }
    }

    private var actionCardsSection: some View {
        VStack(spacing: 10) {
            ActionCard(
                icon: "heart.fill",
                iconColor: .pink1,
                title: "찜 목록",
                subtitle: "좋아요한 게시글"
            ) {
                navigator.push(.likedPosts)
            }

            ActionCard(
                icon: "clock.fill",
                iconColor: .green1,
                title: "거래 내역",
                subtitle: "나의 거래 기록"
            ) {
            }

            ActionCard(
                icon: "rectangle.portrait.and.arrow.right",
                iconColor: .blue1,
                title: "로그아웃",
                subtitle: "계정 로그아웃"
            ) {
                showLogoutAlert = true
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

struct ActionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .Body1()
                        .foregroundColor(.gray1)

                    Text(subtitle)
                        .Body2()
                        .foregroundColor(.gray2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray2)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.gray5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.gray4, lineWidth: 0.5)
            )
        }
    }
}

#Preview {
    SettingView()
        .environmentObject(AppNavigator.shared)
}
