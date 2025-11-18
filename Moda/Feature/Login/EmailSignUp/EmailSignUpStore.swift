//
//  EmailSignUpStore.swift
//  Moda
//
//  Created by 금가경 on 11/17/25.
//

import SwiftUI

final class EmailSignUpStore: ObservableObject {
    @Published private(set) var state = EmailSignUpState()

    private let userAPI: UserAPIProtocol

    init(userAPI: UserAPIProtocol = UserAPI.shared) {
        self.userAPI = userAPI
    }

    func send(_ intent: EmailSignUpIntent) {
        switch intent {
        case .emailChanged(let email):
            validateEmail(email)

        case .passwordChanged(let password):
            validatePassword(password)

        case .confirmPasswordChanged:
            break

        case .nicknameChanged(let nickname):
            validateNickname(nickname)

        case .signUpButtonTapped(let email, let password, let confirmPassword, let nickname):
            signUp(email: email, password: password, confirmPassword: confirmPassword, nickname: nickname)
        }
    }

    func checkPasswordMatch(password: String, confirmPassword: String) {
        if confirmPassword.isEmpty {
            state.isPasswordMatch = false
            return
        }

        state.isPasswordMatch = (password == confirmPassword)
    }

    private func validateEmail(_ email: String) {
        if email.isEmpty {
            state.emailValidationMessage = nil
            state.isEmailValid = false
            return
        }

        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)

        if !emailPredicate.evaluate(with: email) {
            state.emailValidationMessage = "올바른 이메일 형식이 아닙니다"
            state.isEmailValid = false
            return
        }

        Task {
            do {
                let response = try await userAPI.validateEmail(email: email)
                await MainActor.run {
                    state.emailValidationMessage = response.message
                    state.isEmailValid = true
                }
            } catch let error as NetworkError {
                await MainActor.run {
                    state.emailValidationMessage = error.localizedDescription
                    state.isEmailValid = false
                }
            } catch {
                await MainActor.run {
                    state.emailValidationMessage = "이메일 검증에 실패했습니다"
                    state.isEmailValid = false
                }
            }
        }
    }

    private func validatePassword(_ password: String) {
        if password.isEmpty {
            state.passwordValidationMessage = nil
            state.isPasswordValid = false
            return
        }

        if password.count < 4 {
            state.passwordValidationMessage = "비밀번호는 4자 이상이어야 합니다"
            state.isPasswordValid = false
            return
        }

        state.passwordValidationMessage = "사용 가능한 비밀번호입니다"
        state.isPasswordValid = true
    }

    private func validateNickname(_ nickname: String) {
        if nickname.isEmpty {
            state.nicknameValidationMessage = nil
            state.isNicknameValid = false
            return
        }

        // 공백 체크
        if nickname.contains(" ") {
            state.nicknameValidationMessage = "닉네임에 공백을 포함할 수 없습니다"
            state.isNicknameValid = false
            return
        }

        // 특수문자 체크: . , ? * - @ + ^ $ { } ( ) | [ ] \
        let invalidCharacters = CharacterSet(charactersIn: ".,?*-@+^${}()|[]\\")
        if nickname.rangeOfCharacter(from: invalidCharacters) != nil {
            state.nicknameValidationMessage = "닉네임에 특수문자를 포함할 수 없습니다"
            state.isNicknameValid = false
            return
        }

        if nickname.count < 2 || nickname.count > 10 {
            state.nicknameValidationMessage = "닉네임은 2~10자 이내로 입력해주세요"
            state.isNicknameValid = false
            return
        }

        state.nicknameValidationMessage = "사용 가능한 닉네임입니다"
        state.isNicknameValid = true
    }

    private func signUp(email: String, password: String, confirmPassword: String, nickname: String) {
        guard password == confirmPassword else {
            state.errorMessage = "비밀번호가 일치하지 않습니다"
            return
        }

        guard state.canSignUp else {
            state.errorMessage = "입력 정보를 확인해주세요"
            return
        }

        state.isLoading = true
        state.errorMessage = nil

        Task {
            do {
                let response = try await userAPI.signUp(
                    email: email,
                    password: password,
                    nickname: nickname
                )

                await MainActor.run {
                    state.isLoading = false
                    state.isSignUpSuccessful = true

                    TokenManager.shared.saveToken(
                        accessToken: response.accessToken,
                        refreshToken: response.refreshToken
                    )
                }
            } catch let error as NetworkError {
                await MainActor.run {
                    state.isLoading = false
                    state.errorMessage = error.localizedDescription
                }
            } catch {
                await MainActor.run {
                    state.isLoading = false
                    state.errorMessage = "회원가입에 실패했습니다"
                }
            }
        }
    }
}
