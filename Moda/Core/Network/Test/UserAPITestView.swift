//
//  UserAPITestView.swift
//  Moda
//
//  Created by 금가경 on 11/13/24.
//

import SwiftUI

struct UserAPITestState {
    var resultMessage: String = "테스트를 시작하려면 버튼을 눌러주세요."
    var isSuccess: Bool = true
    var isLoading: Bool = false
    var lastSignUpEmail: String?
    var lastSignUpPassword: String?
    var isLoggedIn: Bool = false
}

enum UserAPITestIntent {
    case validateEmailButtonTapped
    case signUpButtonTapped
    case emailLoginButtonTapped
    case kakaoLoginButtonTapped
    case appleLoginButtonTapped
    case withdrawButtonTapped
    case searchUsersButtonTapped
}

final class UserAPITestStore: ObservableObject {
    @Published private(set) var state = UserAPITestState()

    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
    }

    @MainActor
    func send(_ intent: UserAPITestIntent) {
        Task {
            switch intent {
            case .validateEmailButtonTapped:
                await testValidateEmail()
            case .signUpButtonTapped:
                await testSignUp()
            case .emailLoginButtonTapped:
                await testEmailLogin()
            case .kakaoLoginButtonTapped:
                await testKakaoLogin()
            case .appleLoginButtonTapped:
                await testAppleLogin()
            case .withdrawButtonTapped:
                await testWithdraw()
            case .searchUsersButtonTapped:
                await testSearchUsers()
            }
        }
    }

    @MainActor
    private func testValidateEmail() async {
        state.isLoading = true
        state.resultMessage = "이메일 중복 체크 테스트 중...\n"

        do {
            let response = try await networkService.request(
                endpoint: UserRouter.validateEmail(email: "test@sesac.com"),
                responseType: EmailValidationResponse.self
            )

            state.resultMessage += """
            ✅ 성공!
            Message: \(response.message)

            """
            state.isSuccess = true
        } catch {
            handleError(error, testName: "이메일 중복 체크")
        }

        state.isLoading = false
    }

    @MainActor
    private func testSignUp() async {
        state.isLoading = true
        state.resultMessage = "회원가입 테스트 중...\n"

        let email = "\(Int.random(in: 1...10000))@ggg.com"
        let password = "password123!@"

        do {
            let response = try await networkService.request(
                endpoint: UserRouter.signUp(
                    email: email,
                    password: password,
                    nickname: "테스트유저"
                ),
                responseType: SignUpResponse.self
            )

            // 회원가입 성공 시 이메일/비밀번호 저장
            state.lastSignUpEmail = email
            state.lastSignUpPassword = password

            state.resultMessage += """
            ✅ 성공!
            User ID: \(response.userId)
            Email: \(response.email)
            Nickname: \(response.nickname)

            """
            state.isSuccess = true
        } catch {
            handleError(error, testName: "회원가입")
        }

        state.isLoading = false
    }

    @MainActor
    private func testEmailLogin() async {
        state.isLoading = true
        state.resultMessage = "이메일 로그인 테스트 중...\n"

        // 회원가입한 계정 확인
        guard let email = state.lastSignUpEmail,
              let password = state.lastSignUpPassword else {
            state.resultMessage += """
            ❌ 로그인 실패
            먼저 회원가입을 진행해주세요.

            """
            state.isSuccess = false
            state.isLoading = false
            return
        }

        state.resultMessage += "사용 계정: \(email)\n"

        do {
            let response = try await networkService.request(
                endpoint: UserRouter.login(
                    email: email,
                    password: password
                ),
                responseType: LoginResponse.self
            )

            state.resultMessage += """
            ✅ 성공!
            User ID: \(response.userId)
            Email: \(response.email)
            Nick: \(response.nick)
            Access Token: \(response.accessToken.prefix(20))...

            """

            TokenManager.shared.saveToken(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )
            state.isLoggedIn = true

            state.isSuccess = true
        } catch {
            handleError(error, testName: "이메일 로그인")
        }

        state.isLoading = false
    }

    /// 카카오 로그인 테스트
    ///
    /// - Note: 현재 카카오 SDK가 구현되어 있지 않아 유효한 idToken이 없어 동작하지 않습니다.
    @MainActor
    private func testKakaoLogin() async {
        state.isLoading = true
        state.resultMessage = """
        카카오 로그인 테스트 중...
        ⚠️ 유효한 idToken이 필요합니다

        """

        do {
            let response = try await networkService.request(
                endpoint: UserRouter.loginKakao(oauthToken: "test_kakao_token"),
                responseType: LoginResponse.self
            )

            state.resultMessage += """
            ✅ 성공!
            Nick: \(response.nick)

            """
            state.isSuccess = true
        } catch {
            handleError(error, testName: "카카오 로그인")
        }

        state.isLoading = false
    }

    /// 애플 로그인 테스트
    ///
    /// - Note: 현재 애플 SDK가 구현되어 있지 않아 유효한 idToken이 없어 동작하지 않습니다.
    @MainActor
    private func testAppleLogin() async {
        state.isLoading = true
        state.resultMessage = """
        애플 로그인 테스트 중...
        ⚠️ 유효한 idToken이 필요합니다

        """

        do {
            let response = try await networkService.request(
                endpoint: UserRouter.loginApple(token: "test_apple_token"),
                responseType: LoginResponse.self
            )

            state.resultMessage += """
            ✅ 성공!
            Nick: \(response.nick)

            """
            state.isSuccess = true
        } catch {
            handleError(error, testName: "애플 로그인")
        }

        state.isLoading = false
    }

    /// 회원 탈퇴 테스트
    ///
    /// - Note: 현재 로그인된 계정을 탈퇴 처리합니다. 테스트용 계정으로만 실행하세요.
    @MainActor
    private func testWithdraw() async {
        state.isLoading = true
        state.resultMessage = "회원 탈퇴 테스트 중...\n"

        // 토큰 확인
        guard TokenManager.shared.accessToken != nil else {
            state.resultMessage += "❌ 먼저 로그인하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        do {
            let response = try await networkService.request(
                endpoint: UserRouter.withdraw,
                responseType: WithdrawResponse.self
            )

            state.resultMessage += """
            ✅ 회원 탈퇴 성공!
            User ID: \(response.userId)
            Email: \(response.email)
            Nick: \(response.nick)

            """

            // 토큰 삭제
            TokenManager.shared.clearToken()
            state.isLoggedIn = false

            state.isSuccess = true
        } catch {
            handleError(error, testName: "회원 탈퇴")
        }

        state.isLoading = false
    }

    @MainActor
    private func testSearchUsers() async {
        state.isLoading = true
        state.resultMessage = "유저 검색 테스트 중...\n"

        // 토큰 확인
        guard TokenManager.shared.accessToken != nil else {
            state.resultMessage += "❌ 먼저 로그인하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        do {
            let response = try await networkService.request(
                endpoint: UserRouter.searchUsers(query: "jack"),
                responseType: UserSearchResponse.self
            )

            let userList = response.data.prefix(3).enumerated()
                .map { "\($0 + 1). \($1.nick) (\($1.userId))" }
                .joined(separator: "\n")

            state.resultMessage += """
            ✅ 유저 검색 성공!
            검색 결과: \(response.data.count)명
            \(userList)

            """

            state.isSuccess = true
        } catch {
            handleError(error, testName: "유저 검색")
        }

        state.isLoading = false
    }

    @MainActor
    private func handleError(_ error: Error, testName: String) {
        state.resultMessage += "❌ \(testName) 실패\n"

        if let networkError = error as? NetworkError {
            state.resultMessage += "Error: \(networkError.localizedDescription)\n"
        } else {
            state.resultMessage += "Error: \(error.localizedDescription)\n"
        }

        state.isSuccess = false
    }
}

struct UserAPITestView: View {
    @StateObject private var store = UserAPITestStore()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    tokenInfoSection

                    resultSection

                    Divider()

                    buttonListSection
                }
                .padding()
            }
            .navigationTitle("User API 테스트")
        }
    }

    private var tokenInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("로그인 상태")
                .font(.headline)

            HStack {
                Image(systemName: store.state.isLoggedIn ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundColor(store.state.isLoggedIn ? .green : .gray)
                Text(store.state.isLoggedIn ? "로그인됨" : "로그인되지 않음")
                    .font(.caption)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            resultHeader

            ScrollView {
                Text(store.state.resultMessage)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(store.state.isSuccess ? .green : .red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .frame(height: 150)
        }
    }

    private var resultHeader: some View {
        HStack {
            Text("테스트 결과")
                .font(.headline)

            if store.state.isLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
    }

    private var buttonListSection: some View {
        VStack(spacing: 20) {
            // 기본 API 테스트
            TestButton(title: "이메일 중복 체크", intent: .validateEmailButtonTapped, isLoading: store.state.isLoading) {
                store.send(.validateEmailButtonTapped)
            }

            TestButton(title: "회원가입", intent: .signUpButtonTapped, isLoading: store.state.isLoading) {
                store.send(.signUpButtonTapped)
            }

            TestButton(title: "이메일 로그인", intent: .emailLoginButtonTapped, isLoading: store.state.isLoading) {
                store.send(.emailLoginButtonTapped)
            }

            TestButton(title: "카카오 로그인", intent: .kakaoLoginButtonTapped, isLoading: store.state.isLoading) {
                store.send(.kakaoLoginButtonTapped)
            }

            TestButton(title: "애플 로그인", intent: .appleLoginButtonTapped, isLoading: store.state.isLoading) {
                store.send(.appleLoginButtonTapped)
            }

            Divider()

            TestButton(title: "회원 탈퇴", intent: .withdrawButtonTapped, isLoading: store.state.isLoading) {
                store.send(.withdrawButtonTapped)
            }

            TestButton(title: "유저 검색", intent: .searchUsersButtonTapped, isLoading: store.state.isLoading) {
                store.send(.searchUsersButtonTapped)
            }
        }
    }
}

struct TestButton: View {
    let title: String
    let intent: UserAPITestIntent
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "network")
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(.horizontal)
        .disabled(isLoading)
    }
}

#Preview {
    UserAPITestView()
}
