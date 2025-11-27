//
//  LikedPostsStore.swift
//  Moda
//
//  Created by Suji Jang on 11/24/24.
//

import SwiftUI

@MainActor
@Observable
final class LikedPostsStore {
    var state = LikedPostsState()

    private let postAPI: PostAPIProtocol

    init(postAPI: PostAPIProtocol = PostAPI.shared) {
        self.postAPI = postAPI
    }

    func send(_ intent: LikedPostsIntent) {
        switch intent {
        case .onAppear:
            if state.posts.isEmpty {
                loadPosts(refresh: true)
            }

        case .loadMore:
            guard !state.isLoading, state.hasMore else { return }
            loadPosts(refresh: false)

        case .refresh:
            loadPosts(refresh: true)

        case .toggleLike(let postId):
            toggleLike(postId: postId)

        case .postTapped:
            break
        }
    }

    private func loadPosts(refresh: Bool) {
        if refresh {
            state.nextCursor = ""
            state.hasMore = true
        }

        state.isLoading = true
        Task {
            do {
                let cursor = refresh ? nil : (state.nextCursor.isEmpty ? nil : state.nextCursor)
                let response = try await postAPI.getMyLikedPosts(
                    next: cursor,
                    limit: "20",
                    category: nil
                )

                let newPosts = response.data.map { dto -> LikedPost in
                    let firstFile = dto.files.first
                    let mediaURL: URL? = {
                        guard let firstFile = firstFile else { return nil }
                        return URL(string: NetworkConfig.baseURL + "/v1/" + firstFile)
                    }()

                    let profileImageURL: URL? = {
                        guard let profilePath = dto.creator.profileImage else { return nil }
                        return URL(string: NetworkConfig.baseURL + "/v1/" + profilePath)
                    }()

                    let currentUserId = UserDefaults.standard.string(forKey: "userId")
                    let isLiked = dto.likes.contains(currentUserId ?? "")

                    return LikedPost(
                        id: dto.postId,
                        title: dto.title,
                        price: Int(dto.price ?? 0),
                        mediaURL: mediaURL,
                        mediaPath: firstFile,
                        profileImageURL: profileImageURL,
                        nickname: dto.creator.nick,
                        isLiked: isLiked
                    )
                }

                if refresh {
                    state.posts = newPosts
                } else {
                    let existingIds = Set(state.posts.map { $0.id })
                    let unique = newPosts.filter { !existingIds.contains($0.id) }
                    state.posts.append(contentsOf: unique)
                }

                state.nextCursor = response.nextCursor
                state.hasMore = !response.nextCursor.isEmpty && response.nextCursor != "0"
            } catch {
                state.errorMessage = error.localizedDescription
                print("좋아요 게시글 로드 실패: \(error)")
            }
            state.isLoading = false
        }
    }

    private func toggleLike(postId: String) {
        guard let index = state.posts.firstIndex(where: { $0.id == postId }) else { return }

        state.posts[index].isLiked.toggle()
        let newStatus = state.posts[index].isLiked

        Task {
            do {
                _ = try await postAPI.likePost(postId: postId, likeStatus: newStatus)
            } catch {
                // 롤백
                state.posts[index].isLiked.toggle()
                print("좋아요 요청 실패: \(error)")
            }
        }
    }
}
