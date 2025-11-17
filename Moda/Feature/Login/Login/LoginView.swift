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

            Text("친구들과 함께하는 중고거래")
                .Body1()
                .foregroundColor(.gray2)
        }
    }

    private var inputSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("이메일")
                    .Body2()
                    .foregroundColor(.gray2)

                TextField("이메일을 입력해주세요", text: $email)
                    .font(.custom("SUIT-Medium", size: 14))
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.gray5)
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("비밀번호")
                    .Body2()
                    .foregroundColor(.gray2)

                SecureField("비밀번호를 입력해주세요", text: $password)
                    .font(.custom("SUIT-Medium", size: 14))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.gray5)
                    .cornerRadius(8)
            }
        }
    }

    private var loginButtonSection: some View {
        Button {
            navigator.isLoggedIn = true
        } label: {
            Text("로그인")
                .H2()
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue1)
                .cornerRadius(12)
        }
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
                // TODO: 카카오 로그인 구현
            } label: {
                Image(systemName: "message.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.black)
                    .frame(width: 50, height: 50)
                    .background(Color(hex: "#FEE500"))
                    .clipShape(Circle())
            }

            Button {
                // TODO: 애플 로그인 구현
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
