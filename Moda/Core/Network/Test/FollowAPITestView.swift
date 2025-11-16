//
//  FollowAPITestView.swift
//  Moda
//
//  Created by 금가경 on 11/16/24.
//

import SwiftUI

struct FollowAPITestState {
    var resultMessage: String = "테스트를 시작하려면 버튼을 눌러주세요."
    var isSuccess: Bool = true
    var isLoading: Bool = false
    var targetUserId: String = ""
    var currentFollowStatus: Bool?
}

enum FollowAPITestIntent {
    case followButtonTapped
    case unfollowButtonTapped
}

final class FollowAPITestStore: ObservableObject {
    @Published private(set) var state = FollowAPITestState()

    private let followAPI: FollowAPIProtocol

    init(followAPI: FollowAPIProtocol = FollowAPI.shared) {
        self.followAPI = followAPI
    }

    func updateTargetUserId(_ userId: String) {
        state.targetUserId = userId
    }

    @MainActor
    func send(_ intent: FollowAPITestIntent) {
        Task {
            switch intent {
            case .followButtonTapped:
                await testFollow(followStatus: true)
            case .unfollowButtonTapped:
                await testFollow(followStatus: false)
            }
        }
    }

    @MainActor
    private func testFollow(followStatus: Bool) async {
        state.isLoading = true
        let action = followStatus ? "팔로우" : "언팔로우"
        state.resultMessage = "\(action) 테스트 중...\n"

        guard TokenManager.shared.accessToken != nil else {
            state.resultMessage += "❌ 먼저 로그인하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        guard !state.targetUserId.isEmpty else {
            state.resultMessage += "❌ User ID를 입력하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        do {
            let response = try await followAPI.follow(userId: state.targetUserId, followStatus: followStatus)
            let result = response.toDomain()

            state.currentFollowStatus = result.followingStatus

            state.resultMessage += """
            ✅ \(action) 성공!
            내 닉네임: \(result.nick)
            상대 닉네임: \(result.opponentNick)
            팔로우 상태: \(result.followingStatus ? "팔로우 중" : "팔로우 안함")

            """
            state.isSuccess = true
        } catch {
            handleError(error, testName: action)
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

struct FollowAPITestView: View {
    @StateObject private var store = FollowAPITestStore()
    @State private var userIdInput: String = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    userIdInputSection

                    followStatusSection

                    resultSection

                    Divider()

                    buttonListSection
                }
                .padding()
            }
            .navigationTitle("Follow API 테스트")
        }
    }

    private var userIdInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Target User ID")
                .font(.headline)

            HStack {
                TextField("팔로우할 사용자 ID 입력", text: $userIdInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("설정") {
                    store.updateTargetUserId(userIdInput)
                }
                .buttonStyle(.borderedProminent)
            }

            if !store.state.targetUserId.isEmpty {
                Text("현재 설정: \(store.state.targetUserId)")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }

    private var followStatusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("현재 팔로우 상태")
                .font(.headline)

            HStack {
                if let status = store.state.currentFollowStatus {
                    Image(systemName: status ? "person.badge.plus.fill" : "person.badge.minus")
                        .foregroundColor(status ? .green : .gray)
                    Text(status ? "팔로우 중" : "팔로우 안함")
                        .font(.caption)
                } else {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .foregroundColor(.gray)
                    Text("상태 미확인")
                        .font(.caption)
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
        VStack(spacing: 12) {
            FollowTestButton(title: "팔로우", isLoading: store.state.isLoading) {
                store.send(.followButtonTapped)
            }

            FollowTestButton(title: "언팔로우", isLoading: store.state.isLoading) {
                store.send(.unfollowButtonTapped)
            }
        }
    }
}

struct FollowTestButton: View {
    let title: String
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
    FollowAPITestView()
}
