//
//  PostAPIProtocol.swift
//  Moda
//
//  Created by 금가경 on 11/16/24.
//

import Foundation

/// 게시글 관련 API 프로토콜
protocol PostAPIProtocol {
    /// 파일 업로드
    func uploadFiles(files: [FileData]) async throws -> FileUploadResponse

    /// 게시글 작성
    func createPost(
        category: String,
        title: String,
        price: Int?,
        content: String?,
        value1: String?,
        content2: String?,
        content3: String?,
        content4: String?,
        content5: String?,
        files: [String],
        longitude: Double?,
        latitude: Double?
    ) async throws -> PostResponse

    /// 게시글 목록 조회
    func getPosts(next: String?, limit: String?, category: [String]?) async throws -> PostListResponse

    /// 게시글 상세 조회
    func getPost(postId: String) async throws -> PostResponse

    /// 게시글 수정
    func updatePost(
        postId: String,
        category: String?,
        title: String?,
        price: Int?,
        content: String?,
        value1: String?,
        content2: String?,
        content3: String?,
        content4: String?,
        content5: String?,
        files: [String]?,
        longitude: Double?,
        latitude: Double?
    ) async throws -> PostResponse

    /// 게시글 삭제
    func deletePost(postId: String) async throws

    /// 게시글 좋아요/취소
    func likePost(postId: String, likeStatus: Bool) async throws -> LikeResponse

    /// 좋아요한 게시글 조회
    func getMyLikedPosts(next: String?, limit: String?, category: [String]?) async throws -> PostListResponse

    /// 특정 유저 게시글 조회
    func getUserPosts(userId: String, next: String?, limit: String?, category: [String]?) async throws -> PostListResponse

    /// 해시태그 검색
    func searchHashtags(next: String?, limit: String?, category: [String]?, hashTag: String) async throws -> PostListResponse

    /// 팔로우 피드 조회
    func getFeed(next: String?, limit: String?, category: [String]?) async throws -> PostListResponse

    /// 위치기반 게시글 검색
    func getPostsByGeolocation(
        category: [String]?,
        longitude: Double?,
        latitude: Double?,
        maxDistance: Double?,
        orderBy: String?,
        sortBy: String?
    ) async throws -> GeolocationSearchResponse

    /// 제목 검색
    func searchPosts(title: String, category: [String]?) async throws -> TitleSearchResponse

    /// 거래 내역 조회
    func getPaymentList(next: String?, limit: String?) async throws -> PaymentListResponse
}
