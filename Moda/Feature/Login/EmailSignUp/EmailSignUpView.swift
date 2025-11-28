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
    @State private var showErrorAlert = false

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

            if store.state.isLoading {
                LoadingOverlay()
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
        .enableSwipeBack()
        .alert("회원가입 실패", isPresented: $showErrorAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(store.state.errorMessage ?? "알 수 없는 오류가 발생했습니다")
        }
        .onChange(of: store.state.errorMessage) { _, newValue in
            if newValue != nil {
                showErrorAlert = true
            }
        }
        .onChange(of: store.state.isSignUpSuccessful) { _, isSuccessful in
            if isSuccessful {
                navigator.popToRoot()
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
        AuthTextField(
            label: "이메일",
            placeholder: "example@email.com",
            text: $email,
            keyboardType: .emailAddress,
            validationMessage: store.state.emailValidationMessage,
            isValid: store.state.isEmailValid,
            showValidation: true
        )
        .onChange(of: email) { _, newValue in
            store.send(.emailChanged(newValue))
        }
    }

    private var passwordInputField: some View {
        AuthTextField(
            label: "비밀번호",
            placeholder: "4자 이상 입력해주세요",
            text: $password,
            isSecure: true,
            validationMessage: store.state.passwordValidationMessage,
            isValid: store.state.isPasswordValid,
            showValidation: true
        )
        .onChange(of: password) { _, newValue in
            store.send(.passwordChanged(newValue))
            store.checkPasswordMatch(password: newValue, confirmPassword: confirmPassword)
        }
    }

    private var confirmPasswordInputField: some View {
        AuthTextField(
            label: "비밀번호 확인",
            placeholder: "비밀번호를 다시 입력해주세요",
            text: $confirmPassword,
            isSecure: true,
            validationMessage: password != confirmPassword ? "비밀번호가 일치하지 않습니다" : nil,
            isValid: false,
            showValidation: true
        )
        .onChange(of: confirmPassword) { _, newValue in
            store.send(.confirmPasswordChanged(newValue))
            store.checkPasswordMatch(password: password, confirmPassword: newValue)
        }
    }

    private var nicknameInputField: some View {
        AuthTextField(
            label: "닉네임",
            placeholder: "2~10자 이내로 입력해주세요",
            text: $nickname,
            validationMessage: store.state.nicknameValidationMessage,
            isValid: store.state.isNicknameValid,
            showValidation: true
        )
        .onChange(of: nickname) { _, newValue in
            store.send(.nicknameChanged(newValue))
        }
    }

    private var signUpButtonSection: some View {
        Button {
            store.send(.signUpButtonTapped(
                email: email,
                password: password,
                confirmPassword: confirmPassword,
                nickname: nickname
            ))
        } label: {
            Text("가입하기")
                .H2()
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(store.state.canSignUp ? Color.blue1 : Color.gray3)
                .cornerRadius(12)
        }
        .disabled(!store.state.canSignUp)
        .padding(.bottom, 32)
    }
}

#Preview {
    NavigationStack {
        EmailSignUpView()
            .environmentObject(AppNavigator.shared)
    }
}
