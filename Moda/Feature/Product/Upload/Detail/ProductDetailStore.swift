//
//  ProductDetailStore.swift
//  Moda
//
//  Created by Suji Jang on 11/23/24.
//

import Foundation

@MainActor
final class ProductDetailStore: ObservableObject {
    @Published private(set) var state = ProductDetailState()

    private let postId: String
    private let postAPI: PostAPIProtocol

    init(postId: String, postAPI: PostAPIProtocol = PostAPI.shared) {
        self.postId = postId
        self.postAPI = postAPI
    }

    func send(_ intent: ProductDetailIntent) {
        switch intent {
        case .loadPost:
            Task { await loadPost() }

        case .deletePost:
            Task { await deletePost() }

        case .toggleLike:
            Task { await toggleLike() }

        case .showActionSheet:
            state.showActionSheet = true

        case .dismissActionSheet:
            state.showActionSheet = false

        case .showDeleteAlert:
            state.showDeleteAlert = true

        case .dismissDeleteAlert:
            state.showDeleteAlert = false
        }
    }

    private func loadPost() async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            let response = try await postAPI.getPost(postId: postId)
            state.post = response

            // 좋아요 상태 초기화
            let currentUserId = UserDefaultsManager.shared.userId ?? ""
            state.isLiked = response.likes.contains(currentUserId)
            state.likeCount = response.likes.count

            state.isLoading = false
        } catch {
            state.errorMessage = error.localizedDescription
            state.isLoading = false
        }
    }

    private func deletePost() async {
        state.isDeleting = true

        do {
            try await postAPI.deletePost(postId: postId)
            state.isDeleting = false
            NotificationCenter.default.post(name: AppNotification.postDeleted, object: nil)
        } catch {
            state.isDeleting = false
        }
    }

    private func toggleLike() async {
        let newLikeStatus = !state.isLiked

        state.isLiked = newLikeStatus
        state.likeCount += newLikeStatus ? 1 : -1

        do {
            _ = try await postAPI.likePost(postId: postId, likeStatus: newLikeStatus)
            // 성공 시 알림 발송
            NotificationCenter.default.post(
                name: AppNotification.postLikeUpdated,
                object: nil,
                userInfo: ["postId": postId, "isLiked": newLikeStatus, "likeCount": state.likeCount]
            )
        } catch {
            // 실패 시 롤백
            state.isLiked = !newLikeStatus
            state.likeCount += newLikeStatus ? -1 : 1
        }
    }

    func formattedDate(from createdAt: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var parsedDate: Date?

        if let date = isoFormatter.date(from: createdAt) {
            parsedDate = date
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            parsedDate = dateFormatter.date(from: createdAt)
        }

        guard let date = parsedDate else {
            return createdAt
        }

        let now = Date()
        let interval = now.timeIntervalSince(date)

        if interval < 60 {
            return "방금 전"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)분 전"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)시간 전"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)일 전"
        } else {
            let outputFormatter = DateFormatter()
            outputFormatter.locale = Locale(identifier: "ko_KR")
            outputFormatter.dateFormat = "MM.dd"
            return outputFormatter.string(from: date)
        }
    }
}
