//
//  TokenRefreshTestView.swift
//  Moda
//
//  Created by 금가경 on 11/14/24.
//

import SwiftUI

/// 토큰 자동 갱신 기능 테스트용 뷰
///
/// ## 테스트 전 설정
///
/// **중요**: 이 테스트를 실행하기 전에 다음 파일들의 baseURL을 수정해야 합니다:
///
/// 1. **AuthRouter.swift** (Line 52-55):
/// ```swift
/// var baseURL: String {
///     return NetworkConfig.authURL  // baseURL → authURL로 변경
/// }
/// ```
///
/// 2. **UserRouter.swift** (Line 38-40):
/// ```swift
/// var baseURL: String {
///     return NetworkConfig.authURL  // baseURL → authURL로 변경
/// }
/// ```
///
/// ## 테스트 시나리오
/// - 0-60초: AccessToken 유효, 정상 응답
/// - 60-180초: AccessToken 만료, 자동 갱신 후 성공
/// - 180초 이후: RefreshToken 만료, 418 에러

struct TokenRefreshTestState {
    var resultMessage: String = "로그인하여 테스트를 시작하세요."
    var isSuccess: Bool = true
    var isLoading: Bool = false
    var lastSignUpEmail: String?
    var lastSignUpPassword: String?
    var loginTime: Date?
    var currentElapsedTime: Int = 0
}

enum TokenRefreshTestIntent {
    case loginButtonTapped
    case searchUsersButtonTapped
}

final class TokenRefreshTestStore: ObservableObject {
    @Published private(set) var state = TokenRefreshTestState()

    private let networkService: NetworkServiceProtocol
    private var timer: Timer?

    init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
    }

    deinit {
        timer?.invalidate()
    }

    @MainActor
    func send(_ intent: TokenRefreshTestIntent) {
        Task {
            switch intent {
            case .loginButtonTapped:
                await testLogin()
            case .searchUsersButtonTapped:
                await testSearchUsers()
            }
        }
    }

    private func startTimer() {
        state.loginTime = Date()
        state.currentElapsedTime = 0

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let loginTime = self.state.loginTime else { return }
            Task { @MainActor in
                self.state.currentElapsedTime = Int(Date().timeIntervalSince(loginTime))
            }
        }
    }

    @MainActor
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        state.loginTime = nil
        state.currentElapsedTime = 0
    }

    @MainActor
    private func testLogin() async {
        state.isLoading = true
        state.resultMessage = "로그인 중...\n"
        
        let email = "test@kkk.com"
        let password = "password123!@"

        do {
            let response = try await networkService.request(
                endpoint: UserRouter.login(
                    email: email,
                    password: password
                ),
                responseType: LoginResponse.self
            )

            TokenManager.shared.saveToken(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )

            startTimer()

            state.resultMessage += """
            ✅ 로그인 성공!
            Email: \(response.email)

            ⏱️ 타이머가 시작되었습니다.

            📌 테스트 시나리오:
            1. 60초 전: 유저 검색 성공 (토큰 유효)
            2. 60초 ~ 180초: 유저 검색 시 자동으로 토큰 갱신 후 성공
            3. 180초 이후: refreshToken 만료로 실패 (418 에러)

            """
            state.isSuccess = true
        } catch {
            handleError(error, testName: "로그인")
        }

        state.isLoading = false
    }

    @MainActor
    private func testSearchUsers() async {
        state.isLoading = true

        let elapsedTime = state.currentElapsedTime
        state.resultMessage = """
        유저 검색 테스트 중...
        로그인 후 경과 시간: \(elapsedTime)초

        """

        // 토큰 상태 확인
        guard let accessToken = TokenManager.shared.accessToken else {
            state.resultMessage += """
            ❌ 먼저 로그인하세요.

            """
            state.isSuccess = false
            state.isLoading = false
            return
        }

        guard let refreshToken = TokenManager.shared.refreshToken else {
            state.resultMessage += """
            ❌ refreshToken이 없습니다.

            """
            state.isSuccess = false
            state.isLoading = false
            return
        }

        state.resultMessage += """
        현재 토큰 상태:
        - AccessToken: \(accessToken)...
        - RefreshToken: \(refreshToken)...

        """

        do {
            let response = try await networkService.request(
                endpoint: UserRouter.searchUsers(query: "jack"),
                responseType: UserSearchResponse.self
            )

            state.resultMessage += """
            ✅ 유저 검색 성공!
            검색 결과: \(response.data.count)명

            """

            // 시간대별 결과 분석
            if elapsedTime < 60 {
                state.resultMessage += "✓ accessToken이 아직 유효합니다.\n"
            } else if elapsedTime < 180 {
                state.resultMessage += """
                ✓ accessToken이 만료되었지만,
                  refreshToken으로 자동 갱신에 성공했습니다!

                """
            } else {
                state.resultMessage += "⚠️ refreshToken도 만료되었을 시간인데 성공했습니다.\n"
            }

            state.isSuccess = true
        } catch {
            state.resultMessage += "❌ 유저 검색 실패\n"

            if let networkError = error as? NetworkError {
                state.resultMessage += "Error: \(networkError.localizedDescription)\n\n"

                // 418 에러 확인
                if case .serverError(let message) = networkError, message.contains("418") || message.contains("만료") {
                    state.resultMessage += """
                    ✓ refreshToken이 만료되었습니다.
                      이는 정상적인 동작입니다. (180초 경과)

                    """
                    stopTimer()
                } else if elapsedTime >= 60 && elapsedTime < 180 {
                    state.resultMessage += """
                    ⚠️ 토큰 자동 갱신에 실패했습니다.
                      refreshToken은 아직 유효해야 합니다.

                    """
                }
            } else {
                state.resultMessage += "Error: \(error.localizedDescription)\n"
            }

            state.isSuccess = false
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

struct TokenRefreshTestView: View {
    @StateObject private var store = TokenRefreshTestStore()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    timerSection

                    resultSection

                    Divider()

                    buttonSection
                }
                .padding()
            }
            .navigationTitle("토큰 갱신 테스트")
        }
    }

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("토큰 만료 시간")
                .font(.headline)

            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                Text("AccessToken: 60초")
                    .font(.caption)
            }

            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)
                Text("RefreshToken: 180초")
                    .font(.caption)
            }

            Divider()

            if store.state.loginTime != nil {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(timerColor)
                    Text("로그인 후 경과: \(store.state.currentElapsedTime)초")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(timerColor)
                }

                // 상태 표시
                HStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 12, height: 12)
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(statusColor)
                }
            } else {
                HStack {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.gray)
                    Text("로그인되지 않음")
                        .font(.caption)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private var timerColor: Color {
        let elapsed = store.state.currentElapsedTime
        if elapsed < 60 {
            return .green
        } else if elapsed < 180 {
            return .orange
        } else {
            return .red
        }
    }

    private var statusColor: Color {
        let elapsed = store.state.currentElapsedTime
        if elapsed < 60 {
            return .green
        } else if elapsed < 180 {
            return .orange
        } else {
            return .red
        }
    }

    private var statusText: String {
        let elapsed = store.state.currentElapsedTime
        if elapsed < 60 {
            return "AccessToken 유효"
        } else if elapsed < 180 {
            return "AccessToken 만료 (자동 갱신 예상)"
        } else {
            return "RefreshToken 만료"
        }
    }

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("테스트 결과")
                    .font(.headline)

                if store.state.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            ScrollView {
                Text(store.state.resultMessage)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(store.state.isSuccess ? .primary : .red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .frame(height: 200)
        }
    }

    private var buttonSection: some View {
        VStack(spacing: 16) {
            Text("테스트 순서")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: {
                store.send(.loginButtonTapped)
            }) {
                HStack {
                    Text("1. 로그인")
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                .foregroundColor(.green)
                .cornerRadius(10)
            }
            .disabled(store.state.isLoading)

            Button(action: {
                store.send(.searchUsersButtonTapped)
            }) {
                HStack {
                    Text("2. 유저 검색")
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "magnifyingglass")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.1))
                .foregroundColor(.orange)
                .cornerRadius(10)
            }
            .disabled(store.state.isLoading)
        }
    }
}

#Preview {
    TokenRefreshTestView()
}
