//
//  LoginStore.swift
//  Moda
//
//  Created by 금가경 on 11/17/25.
//

import SwiftUI
import KakaoSDKCommon
import KakaoSDKAuth
import KakaoSDKUser

final class LoginStore: ObservableObject {
    @Published private(set) var state = LoginState()

    private let userAPI: UserAPIProtocol

    init(userAPI: UserAPIProtocol = UserAPI.shared) {
        self.userAPI = userAPI
    }

    @MainActor
    func send(_ intent: LoginIntent) {
        switch intent {
        case .loginButtonTapped(let email, let password):
            login(email: email, password: password)
        case .kakaoLoginTapped:
            kakaoLogin()
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

    // MARK: - Kakao Login
    private func kakaoLogin() {
        state.isLoading = true
        state.errorMessage = nil

        Task {
            do {
                // 카카오톡 설치 시 톡 로그인, 아니면 계정 로그인
                let oauthToken = try await acquireKakaoOAuthToken()

                // 서버는 oauthToken(= 카카오 access token)을 요구
                let kakaoAccessToken = oauthToken.accessToken

                // 우리 서버 소셜 로그인
                let response = try await userAPI.loginWithKakao(oauthToken: kakaoAccessToken)

                await MainActor.run {
                    state.isLoading = false
                    state.isLoginSuccessful = true

                    TokenManager.shared.saveToken(
                        accessToken: response.accessToken,
                        refreshToken: response.refreshToken
                    )
                    UserDefaults.standard.set(response.userId, forKey: "userId")
                }
            } catch {
                await MainActor.run {
                    state.isLoading = false
                    let nsError = error as NSError
                    if nsError.domain.lowercased().contains("kakao"),
                       nsError.localizedDescription.isEmpty {
                        state.errorMessage = "카카오 로그인에 실패했습니다"
                    } else {
                        state.errorMessage = nsError.localizedDescription
                    }
                }
            }
        }
    }

    // MARK: - Helpers
    private func acquireKakaoOAuthToken() async throws -> OAuthToken {
        if UserApi.isKakaoTalkLoginAvailable() {
            do {
                return try await loginWithKakaoTalkAsync()
            } catch {
                // 카카오톡 실패/취소 시 카카오계정 로그인으로 폴백
                return try await loginWithKakaoAccountAsync()
            }
        } else {
            return try await loginWithKakaoAccountAsync()
        }
    }

    private func loginWithKakaoTalkAsync() async throws -> OAuthToken {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<OAuthToken, Error>) in
            UserApi.shared.loginWithKakaoTalk { token, error in
                if let token = token {
                    continuation.resume(returning: token)
                } else {
                    continuation.resume(throwing: error ?? NSError(
                        domain: "KakaoLogin",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "카카오톡 로그인에 실패했습니다"]
                    ))
                }
            }
        }
    }

    private func loginWithKakaoAccountAsync() async throws -> OAuthToken {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<OAuthToken, Error>) in
            UserApi.shared.loginWithKakaoAccount { token, error in
                if let token = token {
                    continuation.resume(returning: token)
                } else {
                    continuation.resume(throwing: error ?? NSError(
                        domain: "KakaoLogin",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "카카오계정 로그인에 실패했습니다"]
                    ))
                }
            }
        }
    }
}

