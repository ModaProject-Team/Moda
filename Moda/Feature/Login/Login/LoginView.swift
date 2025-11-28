//
//  LoginView.swift
//  Moda
//
//  Created by 금가경 on 11/17/25.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var store = LoginStore()
    @EnvironmentObject var navigator: AppNavigator
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showErrorAlert = false

    private var canLogin: Bool {
        !email.isEmpty && !password.isEmpty && !store.state.isLoading
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 60)

                    logoSection

                    Spacer()
                        .frame(height: 40)

                    inputSection

                    Spacer()
                        .frame(height: 24)

                    loginButtonSection

                    Spacer()
                        .frame(height: 32)

                    dividerSection

                    Spacer()
                        .frame(height: 24)

                    socialLoginSection

                    Spacer()
                        .frame(height: 32)

                    signUpLinkSection
                }
                .padding(.horizontal, 24)
            }

            if store.state.isLoading {
                LoadingOverlay()
            }
        }
        .alert("로그인 실패", isPresented: $showErrorAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(store.state.errorMessage ?? "알 수 없는 오류가 발생했습니다")
        }
        .onChange(of: store.state.errorMessage) { _, newValue in
            if newValue != nil {
                showErrorAlert = true
            }
        }
        .onChange(of: store.state.isLoginSuccessful) { _, isSuccessful in
            if isSuccessful {
                navigator.isLoggedIn = true
            }
        }
    }

    private var logoSection: some View {
        VStack(spacing: 4) {
            Image("AppIcon")
                .resizable()
                .scaledToFit()
                .frame(height: 100)

            Text("모다")
                .Logo()
                .foregroundColor(.gray1)

            Text("친구와 함께하는 안전한 거래")
                .Body1()
                .foregroundColor(.gray2)
        }
    }

    private var inputSection: some View {
        VStack(spacing: 16) {
            AuthTextField(
                label: "이메일",
                placeholder: "이메일을 입력해주세요",
                text: $email,
                keyboardType: .emailAddress
            )

            AuthTextField(
                label: "비밀번호",
                placeholder: "비밀번호를 입력해주세요",
                text: $password,
                isSecure: true
            )
        }
    }

    private var loginButtonSection: some View {
        Button {
            store.send(.loginButtonTapped(email: email, password: password))
        } label: {
            Text("로그인")
                .H2()
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canLogin ? Color.blue1 : Color.gray3)
                .cornerRadius(12)
        }
        .disabled(!canLogin)
    }

    private var dividerSection: some View {
        HStack {
            Rectangle()
                .fill(Color.gray3)
                .frame(height: 1)

            Text("또는")
                .Body2()
                .foregroundColor(.gray2)
                .padding(.horizontal, 16)

            Rectangle()
                .fill(Color.gray3)
                .frame(height: 1)
        }
    }

    private var socialLoginSection: some View {
        HStack(spacing: 24) {
            Button {
                store.send(.kakaoLoginTapped)
            } label: {
                Image(systemName: "message.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.black)
                    .frame(width: 50, height: 50)
                    .background(Color(hex: "#FEE500"))
                    .clipShape(Circle())
            }

            Button {
                store.send(.appleLoginTapped)
            } label: {
                Image(systemName: "apple.logo")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.black)
                    .clipShape(Circle())
            }
        }
    }

    private var signUpLinkSection: some View {
        HStack(spacing: 4) {
            Text("계정이 없으신가요?")
                .Body2()
                .foregroundColor(.gray2)

            Button {
                navigator.push(.signUp)
            } label: {
                Text("회원가입")
                    .Body2()
                    .foregroundColor(.blue1)
                    .underline()
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AppNavigator.shared)
}

