//
//  ImageCacheServiceProtocol.swift
//  Moda
//
//  Created by 금가경 on 11/30/24.
//

import UIKit

/// 이미지 캐시 서비스 프로토콜
///
/// 테스트를 위한 Mock 구현을 가능하게 합니다.
protocol ImageCacheServiceProtocol {
    /// 이미지 캐싱 (Downsampling 지원)
    /// - Parameters:
    ///   - url: 원본 URL
    ///   - targetSize: 다운샘플링할 타겟 크기 (nil이면 원본 크기)
    /// - Returns: 캐시된 이미지
    /// - Throws: 캐싱 실패 시 에러
    func cacheImage(from url: URL, targetSize: CGSize?) async throws -> UIImage

    /// 캐시된 이미지 조회
    /// - Parameters:
    ///   - url: 원본 URL
    ///   - targetSize: 조회할 크기 (nil이면 원본 크기)
    /// - Returns: 캐시된 이미지 (없으면 nil)
    func getCachedImage(for url: URL, targetSize: CGSize?) -> UIImage?

    /// 전체 캐시 삭제
    func clearCache() async

    /// 용량 초과 시 정리
    func cleanupIfNeeded() async

    /// 메모리 캐시 정리
    func clearMemoryCache()

    /// 특정 URL의 다운로드 취소
    /// - Parameter url: 취소할 이미지 URL
    func cancelImageDownload(for url: URL) async

    /// 모든 다운로드 취소
    func cancelAllDownloads() async

    /// 이미지 미리 다운로드 (백그라운드)
    /// - Parameters:
    ///   - urls: 미리 다운로드할 URL 배열
    ///   - targetSize: 다운샘플링할 타겟 크기
    func prefetchImages(urls: [URL], targetSize: CGSize?)
}
