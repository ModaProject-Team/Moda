//
//  SettingView.swift
//  Moda
//
//  Created by Suji Jang on 11/24/25.
//

import SwiftUI

struct SettingView: View {
    @EnvironmentObject var navigator: AppNavigator
    @State private var store = SettingStore()
    @State private var showLogoutAlert = false

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabHeaderView(title: "프로필")

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        profileCardSection

                        actionCardsSection
                            .padding(.top, 20)
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .task {
            store.send(.onAppear)
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
        Button {
            navigator.push(.profileEdit)
        } label: {
            HStack(spacing: 12) {
                profileImageView
                    .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text(store.state.nickname)
                        .H2()
                        .foregroundColor(.gray1)

                    Text("프로필 설정")
                        .Body2()
                        .foregroundColor(.gray2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private var profileImageView: some View {
        ProfileImageView(imageURL: store.state.profileImageURL, size: 52)
    }

    private var actionCardsSection: some View {
        VStack(spacing: 0) {
            ActionListItem(
                icon: "heart.fill",
                iconColor: .pink1,
                title: "찜 목록",
                subtitle: "좋아요한 게시글"
            ) {
                navigator.push(.likedPosts)
            }

            ActionListItem(
                icon: "clock.fill",
                iconColor: .green1,
                title: "거래 내역",
                subtitle: "나의 거래 기록"
            ) {
                navigator.push(.transactions)
            }

            ActionListItem(
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
        UserDefaultsManager.shared.clearUserData()
        AppNavigator.shared.popToRoot()
        AppNavigator.shared.isLoggedIn = false
    }
}

struct ActionListItem: View {
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
                        .frame(width: 52, height: 52)

                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .H2()
                        .foregroundColor(.gray1)

                    Text(subtitle)
                        .Body2()
                        .foregroundColor(.gray2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingView()
        .environmentObject(AppNavigator.shared)
}
