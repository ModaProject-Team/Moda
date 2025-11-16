//
//  PostAPITestView.swift
//  Moda
//
//  Created by 금가경 on 11/16/24.
//

import SwiftUI

struct PostAPITestState {
    var resultMessage: String = "테스트를 시작하려면 버튼을 눌러주세요."
    var isSuccess: Bool = true
    var isLoading: Bool = false
    var lastCreatedPostId: String?
}

enum PostAPITestIntent {
    case getPostsButtonTapped
    case createPostButtonTapped
    case getPostButtonTapped
    case updatePostButtonTapped
    case deletePostButtonTapped
    case likePostButtonTapped
    case getMyLikedPostsButtonTapped
    case searchHashtagsButtonTapped
    case getFeedButtonTapped
    case getPostsByGeolocationButtonTapped
    case searchPostsButtonTapped
}

final class PostAPITestStore: ObservableObject {
    @Published private(set) var state = PostAPITestState()

    private let postAPI: PostAPIProtocol

    init(postAPI: PostAPIProtocol = PostAPI.shared) {
        self.postAPI = postAPI
    }

    @MainActor
    func send(_ intent: PostAPITestIntent) {
        Task {
            switch intent {
            case .getPostsButtonTapped:
                await testGetPosts()
            case .createPostButtonTapped:
                await testCreatePost()
            case .getPostButtonTapped:
                await testGetPost()
            case .updatePostButtonTapped:
                await testUpdatePost()
            case .deletePostButtonTapped:
                await testDeletePost()
            case .likePostButtonTapped:
                await testLikePost()
            case .getMyLikedPostsButtonTapped:
                await testGetMyLikedPosts()
            case .searchHashtagsButtonTapped:
                await testSearchHashtags()
            case .getFeedButtonTapped:
                await testGetFeed()
            case .getPostsByGeolocationButtonTapped:
                await testGetPostsByGeolocation()
            case .searchPostsButtonTapped:
                await testSearchPosts()
            }
        }
    }

    @MainActor
    private func testGetPosts() async {
        state.isLoading = true
        state.resultMessage = "게시글 목록 조회 테스트 중...\n"

        guard TokenManager.shared.accessToken != nil else {
            state.resultMessage += "❌ 먼저 로그인하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        do {
            let response = try await postAPI.getPosts(next: nil, limit: "5", category: nil)

            let postList = response.data.prefix(3).enumerated()
                .map { "\($0 + 1). \($1.title) - \($1.creator.nick)" }
                .joined(separator: "\n")

            state.resultMessage += """
            ✅ 성공!
            총 \(response.data.count)개 게시글
            Next Cursor: \(response.nextCursor)

            \(postList.isEmpty ? "게시글이 없습니다." : postList)

            """
            state.isSuccess = true
        } catch {
            handleError(error, testName: "게시글 목록 조회")
        }

        state.isLoading = false
    }

    @MainActor
    private func testCreatePost() async {
        state.isLoading = true
        state.resultMessage = "게시글 작성 테스트 중...\n"

        guard TokenManager.shared.accessToken != nil else {
            state.resultMessage += "❌ 먼저 로그인하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        do {
            let response = try await postAPI.createPost(
                category: "test",
                title: "테스트 게시글 \(Int.random(in: 1...1000))",
                price: 100,
                content: "테스트 내용입니다. #테스트 #iOS #Swift",
                content1: nil,
                content2: nil,
                content3: nil,
                content4: nil,
                content5: nil,
                files: [],
                longitude: 126.886417,
                latitude: 37.517682
            )

            state.lastCreatedPostId = response.postId

            state.resultMessage += """
            ✅ 게시글 작성 성공!
            Post ID: \(response.postId)
            Title: \(response.title)
            Category: \(response.category)
            HashTags: \(response.hashTags.joined(separator: ", "))

            """
            state.isSuccess = true
        } catch {
            handleError(error, testName: "게시글 작성")
        }

        state.isLoading = false
    }

    @MainActor
    private func testGetPost() async {
        state.isLoading = true
        state.resultMessage = "게시글 상세 조회 테스트 중...\n"

        guard TokenManager.shared.accessToken != nil else {
            state.resultMessage += "❌ 먼저 로그인하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        guard let postId = state.lastCreatedPostId else {
            state.resultMessage += "❌ 먼저 게시글을 작성하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        do {
            let response = try await postAPI.getPost(postId: postId)

            state.resultMessage += """
            ✅ 게시글 상세 조회 성공!
            Post ID: \(response.postId)
            Title: \(response.title)
            Content: \(response.content ?? "없음")
            Creator: \(response.creator.nick)
            Likes: \(response.likes.count)명
            Comments: \(response.commentCount ?? 0)개

            """
            state.isSuccess = true
        } catch {
            handleError(error, testName: "게시글 상세 조회")
        }

        state.isLoading = false
    }

    @MainActor
    private func testUpdatePost() async {
        state.isLoading = true
        state.resultMessage = "게시글 수정 테스트 중...\n"

        guard TokenManager.shared.accessToken != nil else {
            state.resultMessage += "❌ 먼저 로그인하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        guard let postId = state.lastCreatedPostId else {
            state.resultMessage += "❌ 먼저 게시글을 작성하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        do {
            let response = try await postAPI.updatePost(
                postId: postId,
                category: nil,
                title: "수정된 제목 \(Int.random(in: 1...1000))",
                price: nil,
                content: "수정된 내용입니다. #수정 #업데이트",
                content1: nil,
                content2: nil,
                content3: nil,
                content4: nil,
                content5: nil,
                files: nil,
                longitude: nil,
                latitude: nil
            )

            state.resultMessage += """
            ✅ 게시글 수정 성공!
            Post ID: \(response.postId)
            Title: \(response.title)
            Content: \(response.content ?? "없음")

            """
            state.isSuccess = true
        } catch {
            handleError(error, testName: "게시글 수정")
        }

        state.isLoading = false
    }

    @MainActor
    private func testDeletePost() async {
        state.isLoading = true
        state.resultMessage = "게시글 삭제 테스트 중...\n"

        guard TokenManager.shared.accessToken != nil else {
            state.resultMessage += "❌ 먼저 로그인하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        guard let postId = state.lastCreatedPostId else {
            state.resultMessage += "❌ 먼저 게시글을 작성하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        do {
            try await postAPI.deletePost(postId: postId)

            state.lastCreatedPostId = nil

            state.resultMessage += """
            ✅ 게시글 삭제 성공!
            삭제된 Post ID: \(postId)

            """
            state.isSuccess = true
        } catch {
            handleError(error, testName: "게시글 삭제")
        }

        state.isLoading = false
    }

    @MainActor
    private func testLikePost() async {
        state.isLoading = true
        state.resultMessage = "게시글 좋아요 테스트 중...\n"

        guard TokenManager.shared.accessToken != nil else {
            state.resultMessage += "❌ 먼저 로그인하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        guard let postId = state.lastCreatedPostId else {
            state.resultMessage += "❌ 먼저 게시글을 작성하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        do {
            let response = try await postAPI.likePost(postId: postId, likeStatus: true)

            state.resultMessage += """
            ✅ 게시글 좋아요 성공!
            Like Status: \(response.likeStatus)

            """
            state.isSuccess = true
        } catch {
            handleError(error, testName: "게시글 좋아요")
        }

        state.isLoading = false
    }

    @MainActor
    private func testGetMyLikedPosts() async {
        state.isLoading = true
        state.resultMessage = "좋아요한 게시글 조회 테스트 중...\n"

        guard TokenManager.shared.accessToken != nil else {
            state.resultMessage += "❌ 먼저 로그인하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        do {
            let response = try await postAPI.getMyLikedPosts(next: nil, limit: "5", category: nil)

            let postList = response.data.prefix(3).enumerated()
                .map { "\($0 + 1). \($1.title)" }
                .joined(separator: "\n")

            state.resultMessage += """
            ✅ 좋아요한 게시글 조회 성공!
            총 \(response.data.count)개

            \(postList.isEmpty ? "좋아요한 게시글이 없습니다." : postList)

            """
            state.isSuccess = true
        } catch {
            handleError(error, testName: "좋아요한 게시글 조회")
        }

        state.isLoading = false
    }

    @MainActor
    private func testSearchHashtags() async {
        state.isLoading = true
        state.resultMessage = "해시태그 검색 테스트 중...\n"

        guard TokenManager.shared.accessToken != nil else {
            state.resultMessage += "❌ 먼저 로그인하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        do {
            let response = try await postAPI.searchHashtags(
                next: nil,
                limit: "5",
                category: nil,
                hashTag: "Swift"
            )

            let postList = response.data.prefix(3).enumerated()
                .map { "\($0 + 1). \($1.title)" }
                .joined(separator: "\n")

            state.resultMessage += """
            ✅ 해시태그 검색 성공!
            검색어: #Swift
            총 \(response.data.count)개

            \(postList.isEmpty ? "검색 결과가 없습니다." : postList)

            """
            state.isSuccess = true
        } catch {
            handleError(error, testName: "해시태그 검색")
        }

        state.isLoading = false
    }

    @MainActor
    private func testGetFeed() async {
        state.isLoading = true
        state.resultMessage = "팔로우 피드 조회 테스트 중...\n"

        guard TokenManager.shared.accessToken != nil else {
            state.resultMessage += "❌ 먼저 로그인하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        do {
            let response = try await postAPI.getFeed(next: nil, limit: "5", category: nil)

            let postList = response.data.prefix(3).enumerated()
                .map { "\($0 + 1). \($1.title) - \($1.creator.nick)" }
                .joined(separator: "\n")

            state.resultMessage += """
            ✅ 팔로우 피드 조회 성공!
            총 \(response.data.count)개

            \(postList.isEmpty ? "팔로우한 사용자의 게시글이 없습니다." : postList)

            """
            state.isSuccess = true
        } catch {
            handleError(error, testName: "팔로우 피드 조회")
        }

        state.isLoading = false
    }

    @MainActor
    private func testGetPostsByGeolocation() async {
        state.isLoading = true
        state.resultMessage = "위치기반 게시글 검색 테스트 중...\n"

        guard TokenManager.shared.accessToken != nil else {
            state.resultMessage += "❌ 먼저 로그인하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        do {
            let response = try await postAPI.getPostsByGeolocation(
                category: nil,
                longitude: 126.886417,
                latitude: 37.517682,
                maxDistance: 1000,
                orderBy: "distance",
                sortBy: "asc"
            )

            let postList = response.data.prefix(3).enumerated()
                .map { "\($0 + 1). \($1.title) - \($1.distance ?? 0)m" }
                .joined(separator: "\n")

            state.resultMessage += """
            ✅ 위치기반 검색 성공!
            총 \(response.data.count)개

            \(postList.isEmpty ? "검색 결과가 없습니다." : postList)

            """
            state.isSuccess = true
        } catch {
            handleError(error, testName: "위치기반 게시글 검색")
        }

        state.isLoading = false
    }

    @MainActor
    private func testSearchPosts() async {
        state.isLoading = true
        state.resultMessage = "제목 검색 테스트 중...\n"

        guard TokenManager.shared.accessToken != nil else {
            state.resultMessage += "❌ 먼저 로그인하세요.\n"
            state.isSuccess = false
            state.isLoading = false
            return
        }

        do {
            let response = try await postAPI.searchPosts(title: "테스트", category: nil)

            let postList = response.data.prefix(3).enumerated()
                .map { "\($0 + 1). \($1.title)" }
                .joined(separator: "\n")

            state.resultMessage += """
            ✅ 제목 검색 성공!
            검색어: 테스트
            총 \(response.data.count)개

            \(postList.isEmpty ? "검색 결과가 없습니다." : postList)

            """
            state.isSuccess = true
        } catch {
            handleError(error, testName: "제목 검색")
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

struct PostAPITestView: View {
    @StateObject private var store = PostAPITestStore()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    postIdInfoSection

                    resultSection

                    Divider()

                    buttonListSection
                }
                .padding()
            }
            .navigationTitle("Post API 테스트")
        }
    }

    private var postIdInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("마지막 생성 게시글")
                .font(.headline)

            HStack {
                Image(systemName: store.state.lastCreatedPostId != nil ? "doc.text.fill" : "doc.text")
                    .foregroundColor(store.state.lastCreatedPostId != nil ? .blue : .gray)
                Text(store.state.lastCreatedPostId ?? "없음")
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
            PostTestButton(title: "게시글 목록 조회", isLoading: store.state.isLoading) {
                store.send(.getPostsButtonTapped)
            }

            PostTestButton(title: "게시글 작성", isLoading: store.state.isLoading) {
                store.send(.createPostButtonTapped)
            }

            PostTestButton(title: "게시글 상세 조회", isLoading: store.state.isLoading) {
                store.send(.getPostButtonTapped)
            }

            PostTestButton(title: "게시글 수정", isLoading: store.state.isLoading) {
                store.send(.updatePostButtonTapped)
            }

            PostTestButton(title: "게시글 삭제", isLoading: store.state.isLoading) {
                store.send(.deletePostButtonTapped)
            }

            Divider()

            PostTestButton(title: "게시글 좋아요", isLoading: store.state.isLoading) {
                store.send(.likePostButtonTapped)
            }

            PostTestButton(title: "좋아요한 게시글", isLoading: store.state.isLoading) {
                store.send(.getMyLikedPostsButtonTapped)
            }

            Divider()

            PostTestButton(title: "해시태그 검색", isLoading: store.state.isLoading) {
                store.send(.searchHashtagsButtonTapped)
            }

            PostTestButton(title: "팔로우 피드", isLoading: store.state.isLoading) {
                store.send(.getFeedButtonTapped)
            }

            PostTestButton(title: "위치기반 검색", isLoading: store.state.isLoading) {
                store.send(.getPostsByGeolocationButtonTapped)
            }

            PostTestButton(title: "제목 검색", isLoading: store.state.isLoading) {
                store.send(.searchPostsButtonTapped)
            }
        }
    }
}

struct PostTestButton: View {
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
    PostAPITestView()
}
