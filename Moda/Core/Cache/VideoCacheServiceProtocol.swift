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

    /// 메모리 캐시 정리
    ///
    /// 메모리 경고 시 또는 명시적으로 호출하여 메모리 캐시의 모든 항목을 제거합니다.
    /// 디스크 캐시와 메타데이터는 유지됩니다.
    func clearMemoryCache()

    /// 특정 URL의 다운로드 취소
    /// - Parameter url: 취소할 동영상 URL
    func cancelVideoDownload(for url: URL) async

    /// 모든 다운로드 취소
    func cancelAllDownloads() async

    /// 동영상 미리 다운로드 (백그라운드)
    /// - Parameter urls: 미리 다운로드할 URL 배열
    func prefetchVideos(urls: [URL])

    /// 썸네일 미리 다운로드 (백그라운드)
    /// - Parameter urls: 미리 다운로드할 동영상 URL 배열
    func prefetchThumbnails(urls: [URL])
}
