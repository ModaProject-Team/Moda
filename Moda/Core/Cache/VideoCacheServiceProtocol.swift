//
//  VideoCacheServiceProtocol.swift
//  Moda
//
//  Created by 금가경 on 11/30/24.
//

import UIKit

/// 동영상 캐시 서비스 프로토콜
///
/// 테스트를 위한 Mock 구현을 가능하게 합니다.
protocol VideoCacheServiceProtocol {
    /// 동영상 캐싱
    /// - Parameter url: 원본 URL
    /// - Returns: 캐시된 로컬 URL
    /// - Throws: 캐싱 실패 시 에러
    func cacheVideo(from url: URL) async throws -> URL

    /// 캐시된 동영상 조회
    /// - Parameter url: 원본 URL
    /// - Returns: 캐시된 로컬 URL (없으면 nil)
    func getCachedVideo(for url: URL) -> URL?

    /// 썸네일 캐싱
    /// - Parameter videoURL: 동영상 URL
    /// - Returns: 썸네일 이미지
    /// - Throws: 썸네일 생성 실패 시 에러
    func cacheThumbnail(from videoURL: URL) async throws -> UIImage

    /// 캐시된 썸네일 조회
    /// - Parameter url: 동영상 URL
    /// - Returns: 캐시된 썸네일 (없으면 nil)
    func getCachedThumbnail(for url: URL) -> UIImage?

    /// 전체 캐시 삭제
    func clearCache() async

    /// 용량 초과 시 정리
    func cleanupIfNeeded() async
}
