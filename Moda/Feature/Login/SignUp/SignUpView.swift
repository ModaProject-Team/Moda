//
//  SignUpView.swift
//  Moda
//
//  Created by 금가경 on 11/17/25.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var navigator: AppNavigator

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                headerSection

                Spacer()

                signUpOptionsSection

                Spacer()
                    .frame(height: 60)

                loginLinkSection

                Spacer()
                    .frame(height: 32)
            }
            .padding(.horizontal, 24)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    navigator.pop()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.gray1)
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image("AppIcon")
                .resizable()
                .scaledToFit()
                .frame(height: 80)

            Text("회원가입")
                .H1()
                .foregroundColor(.gray1)

            Text("모다와 함께 중고거래를 시작해보세요")
                .Body1()
                .foregroundColor(.gray2)
        }
    }

    private var signUpOptionsSection: some View {
        VStack(spacing: 12) {
            Button {
                navigator.push(.emailSignUp)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 18))
                    Text("이메일로 시작하기")
                        .H2()
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.gray1)
                .cornerRadius(12)
            }

            Button {
                // TODO: 카카오 회원가입 구현
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 18))
                    Text("카카오로 시작하기")
                        .H2()
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "#FEE500"))
                .cornerRadius(12)
            }

            Button {
                // TODO: 애플 회원가입 구현
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 18))
                    Text("Apple로 시작하기")
                        .H2()
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.black)
                .cornerRadius(12)
            }
        }
    }

    private var loginLinkSection: some View {
        HStack(spacing: 4) {
            Text("이미 계정이 있으신가요?")
                .Body2()
                .foregroundColor(.gray2)

            Button {
                navigator.pop()
            } label: {
                Text("로그인")
                    .Body2()
                    .foregroundColor(.gray1)
                    .underline()
            }
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environmentObject(AppNavigator.shared)
    }
}
