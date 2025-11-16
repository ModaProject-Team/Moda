//
//  UserProfileAPITestView.swift
//  Moda
//
//  Created by 금가경 on 11/15/24.
//

import SwiftUI

struct UserProfileAPITestState {
    var resultMessage: String = "테스트를 시작하려면 버튼을 눌러주세요."
    var isSuccess: Bool = true
    var isLoading: Bool = false
    var isLoggedIn: Bool = false
    var currentProfile: UserProfile?
}

enum UserProfileAPITestIntent {
    case loginButtonTapped
    case getMyProfileButtonTapped
    case getUserProfileButtonTapped(userId: String)
    case updateProfileButtonTapped
}

final class UserProfileAPITestStore: ObservableObject {
    @Published private(set) var state = UserProfileAPITestState()

    @MainActor
    func send(_ intent: UserProfileAPITestIntent) {
        Task {
            switch intent {
            case .loginButtonTapped:
                await testLogin()
            case .getMyProfileButtonTapped:
                await testGetMyProfile()
            case .getUserProfileButtonTapped(let userId):
                await testGetUserProfile(userId: userId)
            case .updateProfileButtonTapped:
                await testUpdateProfile()
            }
        }
    }

    @MainActor
    private func testLogin() async {
        state.isLoading = true
        state.resultMessage = "로그인 테스트 중...\n"

        let email = "profile_test@test.com"
        let password = "test1234!"

        do {
            // 먼저 회원가입 시도
            state.resultMessage += "회원가입 시도...\n"
            _ = try await UserAPI.shared.signUp(
                email: email,
                password: password,
                nickname: "프로필테스트"
            )
            state.resultMessage += "회원가입 성공!\n"
        } catch {
            state.resultMessage += "이미 가입된 계정 또는 회원가입 실패\n"
        }

        do {
            // 로그인
            state.resultMessage += "로그인 시도...\n"
            let response = try await UserAPI.shared.login(
                email: email,
                password: password
            )

            state.isLoggedIn = true

            state.resultMessage += """
            ✅ 로그인 성공!
            User ID: \(response.userId)
            Nick: \(response.nick)
            Token: \(response.accessToken.prefix(20))...

            """
            state.isSuccess = true
        } catch {
            handleError(error, testName: "로그인")
        }

        state.isLoading = false
    }

    @MainActor
    private func testGetMyProfile() async {
        state.isLoading = true
        state.resultMessage = "내 프로필 조회 테스트 중...\n"

        do {
            let response = try await UserProfileAPI.shared.getMyProfile()
            state.currentProfile = response.toDomain()

            state.resultMessage += """
            ✅ 성공!
            User ID: \(response.userId)
            Email: \(response.email)
            Nick: \(response.nick)
            팔로워: \(response.followers.count)명
            팔로잉: \(response.following.count)명
            게시글: \(response.posts.count)개

            """
            state.isSuccess = true
        } catch {
            handleError(error, testName: "내 프로필 조회")
        }

        state.isLoading = false
    }

    @MainActor
    private func testGetUserProfile(userId: String) async {
        state.isLoading = true
        state.resultMessage = "다른 사람 프로필 조회 테스트 중...\n사용자 ID: \(userId)\n"

        do {
            let response = try await UserProfileAPI.shared.getUserProfile(userId: userId)
            state.currentProfile = response.toDomain()

            state.resultMessage += """
            ✅ 성공!
            User ID: \(response.userId)
            Nick: \(response.nick)
            팔로워: \(response.followers.count)명
            팔로잉: \(response.following.count)명
            게시글: \(response.posts.count)개

            """
            state.isSuccess = true
        } catch {
            handleError(error, testName: "다른 사람 프로필 조회")
        }

        state.isLoading = false
    }

    @MainActor
    private func testUpdateProfile() async {
        state.isLoading = true
        state.resultMessage = "프로필 수정 테스트 중...\n"

        do {
            // 테스트용 더미 이미지 데이터 생성
            let testImageData = createTestImageData()

            let response = try await UserProfileAPI.shared.updateMyProfile(
                nick: "테스트닉네임\(Int.random(in: 1...100))",
                phoneNum: nil,
                birthDay: nil,
                profileImage: testImageData,
                info1: "안녕하세요 테스트입니다",
                info2: "SwiftUI 공부중",
                info3: nil,
                info4: nil,
                info5: nil
            )

            state.currentProfile = response.toDomain()

            state.resultMessage += """
            ✅ 프로필 수정 성공!
            Nick: \(response.nick)
            ProfileImage: \(response.profileImage ?? "없음")
            Info1: \(response.info1 ?? "없음")
            Info2: \(response.info2 ?? "없음")

            """
            state.isSuccess = true
        } catch {
            handleError(error, testName: "프로필 수정")
        }

        state.isLoading = false
    }

    private func createTestImageData() -> Data {
        // 1x1 픽셀 빨간색 JPEG 이미지 데이터
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }

        return image.jpegData(compressionQuality: 0.8) ?? Data()
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

struct UserProfileAPITestView: View {
    @StateObject private var store = UserProfileAPITestStore()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    profileInfoSection

                    resultSection

                    Divider()

                    buttonListSection
                }
                .padding()
            }
            .navigationTitle("UserProfile API 테스트")
        }
    }

    private var profileInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("로그인 상태")
                .font(.headline)

            HStack {
                Image(systemName: store.state.isLoggedIn ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundColor(store.state.isLoggedIn ? .green : .gray)
                Text(store.state.isLoggedIn ? "로그인됨" : "로그인되지 않음")
                    .font(.caption)
            }

            if let profile = store.state.currentProfile {
                Divider()
                Text("현재 프로필")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                VStack(alignment: .leading, spacing: 4) {
                    Text("닉네임: \(profile.nickname)")
                        .font(.caption)
                    if let email = profile.email {
                        Text("이메일: \(email)")
                            .font(.caption)
                    }
                    if let info1 = profile.info1 {
                        Text("Info1: \(info1)")
                            .font(.caption)
                    }
                }
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
            .frame(height: 200)
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
            ProfileTestButton(title: "로그인 (테스트 계정)", isLoading: store.state.isLoading) {
                store.send(.loginButtonTapped)
            }

            Divider()

            ProfileTestButton(title: "내 프로필 조회", isLoading: store.state.isLoading) {
                store.send(.getMyProfileButtonTapped)
            }

            ProfileTestButton(title: "다른 사람 프로필 조회 (테스트 ID)", isLoading: store.state.isLoading) {
                store.send(.getUserProfileButtonTapped(userId: "(테스트 id/수정 필요)"))
            }

            ProfileTestButton(title: "프로필 수정", isLoading: store.state.isLoading) {
                store.send(.updateProfileButtonTapped)
            }
        }
    }
}

struct ProfileTestButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "person.circle")
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
    UserProfileAPITestView()
}
