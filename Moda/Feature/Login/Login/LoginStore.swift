//
//  LoginStore.swift
//  Moda
//
//  Created by 금가경 on 11/17/25.
//

import SwiftUI

final class LoginStore: ObservableObject {
    @Published private(set) var state = LoginState()

    private let userAPI: UserAPIProtocol

    init(userAPI: UserAPIProtocol = UserAPI.shared) {
        self.userAPI = userAPI
    }

    func send(_ intent: LoginIntent) {
        switch intent {
        case .loginButtonTapped(let email, let password):
            login(email: email, password: password)
        }
    }

    private func login(email: String, password: String) {
        guard !email.isEmpty && !password.isEmpty else {
            state.errorMessage = "이메일과 비밀번호를 입력해주세요"
            return
        }

        state.isLoading = true
        state.errorMessage = nil

        Task {
            do {
                let response = try await userAPI.login(
                    email: email,
                    password: password
                )

                await MainActor.run {
                    state.isLoading = false
                    state.isLoginSuccessful = true

                    TokenManager.shared.saveToken(
                        accessToken: response.accessToken,
                        refreshToken: response.refreshToken
                    )
                    
                    #warning("임의로 넣어둠")
                    UserDefaults.standard.set(response.userId, forKey: "userId")
                }
            } catch let error as NetworkError {
                await MainActor.run {
                    state.isLoading = false
                    state.errorMessage = error.localizedDescription
                }
            } catch {
                await MainActor.run {
                    state.isLoading = false
                    state.errorMessage = "로그인에 실패했습니다"
                }
            }
        }
    }
}
