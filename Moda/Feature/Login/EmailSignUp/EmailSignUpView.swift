//
//  EmailSignUpView.swift
//  Moda
//
//  Created by 금가경 on 11/17/25.
//

import SwiftUI

struct EmailSignUpView: View {
    @StateObject private var store = EmailSignUpStore()
    @EnvironmentObject var navigator: AppNavigator
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var nickname: String = ""

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 20)

                    headerSection

                    Spacer()
                        .frame(height: 32)

                    inputSection

                    Spacer()
                        .frame(height: 32)

                    signUpButtonSection
                }
                .padding(.horizontal, 24)
            }
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
        VStack(spacing: 8) {
            Text("이메일로 가입하기")
                .H1()
                .foregroundColor(.gray1)

            Text("모다에서 사용할 정보를 입력해주세요")
                .Body1()
                .foregroundColor(.gray2)
        }
    }

    private var inputSection: some View {
        VStack(spacing: 20) {
            emailInputField
            passwordInputField
            confirmPasswordInputField
            nicknameInputField
        }
    }

    private var emailInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("이메일")
                .Body2()
                .foregroundColor(.gray2)

            TextField("example@email.com", text: $email)
                .Input()
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.gray5)
                .cornerRadius(8)
        }
    }

    private var passwordInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("비밀번호")
                .Body2()
                .foregroundColor(.gray2)

            SecureField("6자 이상 입력해주세요", text: $password)
                .Input()
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.gray5)
                .cornerRadius(8)
        }
    }

    private var confirmPasswordInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("비밀번호 확인")
                .Body2()
                .foregroundColor(.gray2)

            SecureField("비밀번호를 다시 입력해주세요", text: $confirmPassword)
                .Input()
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.gray5)
                .cornerRadius(8)
        }
    }

    private var nicknameInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("닉네임")
                .Body2()
                .foregroundColor(.gray2)

            TextField("2~10자 이내로 입력해주세요", text: $nickname)
                .Input()
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.gray5)
                .cornerRadius(8)
        }
    }

    private var signUpButtonSection: some View {
        Button {
            navigator.popToRoot()
        } label: {
            Text("가입하기")
                .H2()
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue1)
                .cornerRadius(12)
        }
        .padding(.bottom, 32)
    }
}

#Preview {
    NavigationStack {
        EmailSignUpView()
            .environmentObject(AppNavigator.shared)
    }
}
