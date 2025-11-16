//
//  CommentAPITestView.swift
//  Moda
//
//  Created by 금가경 on 11/16/24.
//

import SwiftUI

struct CommentAPITestState {
    var resultMessage: String = "테스트를 시작하려면 버튼을 눌러주세요."
    var isSuccess: Bool = true
    var isLoading: Bool = false
    var testPostId: String = ""
    var lastCreatedCommentId: String?
}

enum CommentAPITestIntent {
    case getCommentsButtonTapped
    case createCommentButtonTapped
    case updateCommentButtonTapped
    case deleteCommentButtonTapped
    case createReplyButtonTapped
}

final class CommentAPITestStore: ObservableObject {
    @Published private(set) var state = CommentAPITestState()

    private let commentAPI: CommentAPIProtocol
    private let postAPI: PostAPIProtocol

    init(
        commentAPI: CommentAPIProtocol = CommentAPI.shared,
        postAPI: PostAPIProtocol = PostAPI.shared
    ) {
        self.commentAPI = commentAPI
        self.postAPI = postAPI
    }

    func updatePostId(_ postId: String) {
        state.testPostId = postId
    }

    @MainActor
    func send(_ intent: CommentAPITestIntent) {
        Task {
            switch intent {
            case .getCommentsButtonTapped:
                await testGetComments()
            case .createCommentButtonTapped:
                await testCreateComment()
            case .updateCommentButtonTapped:
                await testUpdateComment()
            case .deleteCommentButtonTapped:
                await testDeleteComment()
            case .createReplyButtonTapped:
                await testCreateReply()
            }
        }
    }

    @MainActor
    private func testGetComments() async {
        state.isLoading = true
        state.resultMessage = "댓글 목록 조회 테스트 중...\n"

        guard TokenManager.shared.accessToken != nil else {
            state.resultMessage += "❌ 먼저 로그인하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        guard !state.testPostId.isEmpty else {
            state.resultMessage += "❌ Post ID를 입력하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        do {
            let response = try await commentAPI.getComments(postId: state.testPostId)
            let comments = response.toDomain()

            let commentList = comments.prefix(3).enumerated()
                .map { index, comment in
                    let replyCount = comment.replies?.count ?? 0
                    return "\(index + 1). \(comment.creator.nickname): \(comment.content.prefix(20))... (답글 \(replyCount)개)"
                }
                .joined(separator: "\n")

            state.resultMessage += """
            ✅ 댓글 조회 성공!
            총 \(comments.count)개 댓글

            \(commentList.isEmpty ? "댓글이 없습니다." : commentList)

            """
            state.isSuccess = true
        } catch {
            handleError(error, testName: "댓글 목록 조회")
        }

        state.isLoading = false
    }

    @MainActor
    private func testCreateComment() async {
        state.isLoading = true
        state.resultMessage = "댓글 작성 테스트 중...\n"

        guard TokenManager.shared.accessToken != nil else {
            state.resultMessage += "❌ 먼저 로그인하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        guard !state.testPostId.isEmpty else {
            state.resultMessage += "❌ Post ID를 입력하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        do {
            let response = try await commentAPI.createComment(
                postId: state.testPostId,
                content: "테스트 댓글입니다. \(Int.random(in: 1...1000))"
            )
            let comment = response.toDomain()

            state.lastCreatedCommentId = comment.commentId

            state.resultMessage += """
            ✅ 댓글 작성 성공!
            Comment ID: \(comment.commentId)
            Content: \(comment.content)
            Creator: \(comment.creator.nickname)

            """
            state.isSuccess = true
        } catch {
            handleError(error, testName: "댓글 작성")
        }

        state.isLoading = false
    }

    @MainActor
    private func testUpdateComment() async {
        state.isLoading = true
        state.resultMessage = "댓글 수정 테스트 중...\n"

        guard TokenManager.shared.accessToken != nil else {
            state.resultMessage += "❌ 먼저 로그인하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        guard !state.testPostId.isEmpty else {
            state.resultMessage += "❌ Post ID를 입력하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        guard let commentId = state.lastCreatedCommentId else {
            state.resultMessage += "❌ 먼저 댓글을 작성하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        do {
            let response = try await commentAPI.updateComment(
                postId: state.testPostId,
                commentId: commentId,
                content: "수정된 댓글입니다. \(Int.random(in: 1...1000))"
            )
            let comment = response.toDomain()

            state.resultMessage += """
            ✅ 댓글 수정 성공!
            Comment ID: \(comment.commentId)
            Content: \(comment.content)

            """
            state.isSuccess = true
        } catch {
            handleError(error, testName: "댓글 수정")
        }

        state.isLoading = false
    }

    @MainActor
    private func testDeleteComment() async {
        state.isLoading = true
        state.resultMessage = "댓글 삭제 테스트 중...\n"

        guard TokenManager.shared.accessToken != nil else {
            state.resultMessage += "❌ 먼저 로그인하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        guard !state.testPostId.isEmpty else {
            state.resultMessage += "❌ Post ID를 입력하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        guard let commentId = state.lastCreatedCommentId else {
            state.resultMessage += "❌ 먼저 댓글을 작성하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        do {
            try await commentAPI.deleteComment(postId: state.testPostId, commentId: commentId)

            state.lastCreatedCommentId = nil

            state.resultMessage += """
            ✅ 댓글 삭제 성공!
            삭제된 Comment ID: \(commentId)

            """
            state.isSuccess = true
        } catch {
            handleError(error, testName: "댓글 삭제")
        }

        state.isLoading = false
    }

    @MainActor
    private func testCreateReply() async {
        state.isLoading = true
        state.resultMessage = "대댓글 작성 테스트 중...\n"

        guard TokenManager.shared.accessToken != nil else {
            state.resultMessage += "❌ 먼저 로그인하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        guard !state.testPostId.isEmpty else {
            state.resultMessage += "❌ Post ID를 입력하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        guard let commentId = state.lastCreatedCommentId else {
            state.resultMessage += "❌ 먼저 댓글을 작성하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        do {
            let response = try await commentAPI.createReply(
                postId: state.testPostId,
                commentId: commentId,
                content: "테스트 대댓글입니다. \(Int.random(in: 1...1000))"
            )
            let reply = response.toDomain()

            state.resultMessage += """
            ✅ 대댓글 작성 성공!
            Reply ID: \(reply.commentId)
            Content: \(reply.content)
            Creator: \(reply.creator.nickname)

            """
            state.isSuccess = true
        } catch {
            handleError(error, testName: "대댓글 작성")
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

struct CommentAPITestView: View {
    @StateObject private var store = CommentAPITestStore()
    @State private var postIdInput: String = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    postIdInputSection

                    commentIdInfoSection

                    resultSection

                    Divider()

                    buttonListSection
                }
                .padding()
            }
            .navigationTitle("Comment API 테스트")
        }
    }

    private var postIdInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Post ID")
                .font(.headline)

            HStack {
                TextField("테스트할 게시글 ID 입력", text: $postIdInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("설정") {
                    store.updatePostId(postIdInput)
                }
                .buttonStyle(.borderedProminent)
            }

            if !store.state.testPostId.isEmpty {
                Text("현재 설정: \(store.state.testPostId)")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }

    private var commentIdInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("마지막 생성 댓글")
                .font(.headline)

            HStack {
                Image(systemName: store.state.lastCreatedCommentId != nil ? "text.bubble.fill" : "text.bubble")
                    .foregroundColor(store.state.lastCreatedCommentId != nil ? .blue : .gray)
                Text(store.state.lastCreatedCommentId ?? "없음")
                    .font(.caption)
                    .lineLimit(1)
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
            CommentTestButton(title: "댓글 목록 조회", isLoading: store.state.isLoading) {
                store.send(.getCommentsButtonTapped)
            }

            CommentTestButton(title: "댓글 작성", isLoading: store.state.isLoading) {
                store.send(.createCommentButtonTapped)
            }

            CommentTestButton(title: "댓글 수정", isLoading: store.state.isLoading) {
                store.send(.updateCommentButtonTapped)
            }

            CommentTestButton(title: "댓글 삭제", isLoading: store.state.isLoading) {
                store.send(.deleteCommentButtonTapped)
            }

            Divider()

            CommentTestButton(title: "대댓글 작성", isLoading: store.state.isLoading) {
                store.send(.createReplyButtonTapped)
            }
        }
    }
}

struct CommentTestButton: View {
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
    CommentAPITestView()
}
