//
//  PostAPI.swift
//  Moda
//
//  Created by 금가경 on 11/16/24.
//

import Foundation

/// 게시글 관련 API 통신을 처리하는 클래스
///
/// 게시글 CRUD, 좋아요, 검색 등 게시글 관련 API 호출을 제공합니다.
final class PostAPI: PostAPIProtocol {
    static let shared = PostAPI()

    private let networkService: NetworkServiceProtocol

    private init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
    }

    func uploadFiles(files: [FileData]) async throws -> FileUploadResponse {
        let endpoint = PostRouter.uploadFiles(files: files)

        guard let multipartData = endpoint.multipartData() else {
            throw NetworkError.invalidURL
        }

        var request = try endpoint.asURLRequest()
        request.setValue("multipart/form-data; boundary=\(multipartData.boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = multipartData.data

        let (data, urlResponse) = try await URLSession.shared.data(for: request)

        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(message: "상태 코드: \(httpResponse.statusCode)")
        }

        let response = try JSONDecoder().decode(FileUploadResponse.self, from: data)
        return response
    }

    func createPost(
        category: String,
        title: String,
        price: Int? = nil,
        content: String? = nil,
        value1: String? = nil,
        content2: String? = nil,
        content3: String? = nil,
        content4: String? = nil,
        content5: String? = nil,
        files: [String] = [],
        longitude: Double? = nil,
        latitude: Double? = nil
    ) async throws -> PostResponse {
        let endpoint = PostRouter.createPost(
            category: category,
            title: title,
            price: price,
            content: content,
            value1: value1,
            content2: content2,
            content3: content3,
            content4: content4,
            content5: content5,
            files: files,
            longitude: longitude,
            latitude: latitude
        )

        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: PostResponse.self
        )

        return response
    }

    func getPosts(next: String? = nil, limit: String? = nil, category: [String]? = nil) async throws -> PostListResponse {
        let endpoint = PostRouter.getPosts(next: next, limit: limit, category: category)
        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: PostListResponse.self
        )

        return response
    }

    func getPost(postId: String) async throws -> PostResponse {
        let endpoint = PostRouter.getPost(postId: postId)
        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: PostResponse.self
        )

        return response
    }

    func updatePost(
        postId: String,
        category: String? = nil,
        title: String? = nil,
        price: Int? = nil,
        content: String? = nil,
        value1: String? = nil,
        content2: String? = nil,
        content3: String? = nil,
        content4: String? = nil,
        content5: String? = nil,
        files: [String]? = nil,
        longitude: Double? = nil,
        latitude: Double? = nil
    ) async throws -> PostResponse {
        let endpoint = PostRouter.updatePost(
            postId: postId,
            category: category,
            title: title,
            price: price,
            content: content,
            value1: value1,
            content2: content2,
            content3: content3,
            content4: content4,
            content5: content5,
            files: files,
            longitude: longitude,
            latitude: latitude
        )

        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: PostResponse.self
        )

        return response
    }

    func deletePost(postId: String) async throws {
        let endpoint = PostRouter.deletePost(postId: postId)
        try await networkService.requestWithoutResponse(endpoint: endpoint)
    }

    func likePost(postId: String, likeStatus: Bool) async throws -> LikeResponse {
        let endpoint = PostRouter.likePost(postId: postId, likeStatus: likeStatus)
        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: LikeResponse.self
        )

        return response
    }

    func getMyLikedPosts(next: String? = nil, limit: String? = nil, category: [String]? = nil) async throws -> PostListResponse {
        let endpoint = PostRouter.getMyLikedPosts(next: next, limit: limit, category: category)
        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: PostListResponse.self
        )

        return response
    }

    func getUserPosts(userId: String, next: String? = nil, limit: String? = nil, category: [String]? = nil) async throws -> PostListResponse {
        let endpoint = PostRouter.getUserPosts(userId: userId, next: next, limit: limit, category: category)
        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: PostListResponse.self
        )

        return response
    }

    func searchHashtags(next: String? = nil, limit: String? = nil, category: [String]? = nil, hashTag: String) async throws -> PostListResponse {
        let endpoint = PostRouter.searchHashtags(next: next, limit: limit, category: category, hashTag: hashTag)
        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: PostListResponse.self
        )

        return response
    }

    func getFeed(next: String? = nil, limit: String? = nil, category: [String]? = nil) async throws -> PostListResponse {
        let endpoint = PostRouter.getFeed(next: next, limit: limit, category: category)
        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: PostListResponse.self
        )

        return response
    }

    func getPostsByGeolocation(
        category: [String]? = nil,
        longitude: Double? = nil,
        latitude: Double? = nil,
        maxDistance: Double? = nil,
        orderBy: String? = nil,
        sortBy: String? = nil
    ) async throws -> GeolocationSearchResponse {
        let endpoint = PostRouter.getPostsByGeolocation(
            category: category,
            longitude: longitude,
            latitude: latitude,
            maxDistance: maxDistance,
            orderBy: orderBy,
            sortBy: sortBy
        )

        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: GeolocationSearchResponse.self
        )

        return response
    }

    func searchPosts(title: String, category: [String]? = nil) async throws -> TitleSearchResponse {
        let endpoint = PostRouter.searchPosts(title: title, category: category)
        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: TitleSearchResponse.self
        )

        return response
    }

    func getPaymentList(next: String? = nil, limit: String? = nil) async throws -> PaymentListResponse {
        let endpoint = PostRouter.getPaymentList(next: next, limit: limit)
        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: PaymentListResponse.self
        )

        return response
    }
}
