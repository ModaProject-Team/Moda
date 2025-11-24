//
//  SettingView.swift
//  Moda
//
//  Created by Suji Jang on 11/24/25.
//

import SwiftUI

struct SettingView: View {
    @State private var showProfileEdit = false
    @State private var showLogoutAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showProfileEdit = true
                    } label: {
                        HStack {
                            Image(systemName: "person.circle")
                                .foregroundColor(.blue1)
                            Text("프로필 수정")
                                .foregroundColor(.primary)
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showLogoutAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("로그아웃")
                        }
                    }
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showProfileEdit) {
                ProfileEditView()
            }
            .alert("로그아웃", isPresented: $showLogoutAlert) {
                Button("취소", role: .cancel) { }
                Button("로그아웃", role: .destructive) {
                    logout()
                }
            } message: {
                Text("정말 로그아웃 하시겠습니까?")
            }
        }
    }

    private func logout() {
        TokenManager.shared.clearToken()
        UserDefaults.standard.removeObject(forKey: "userId")
    }
}

#Preview {
    SettingView()
}
