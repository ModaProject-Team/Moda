//
//  CacheConfig.swift
//  Moda
//
//  Created by 금가경 on 11/30/24.
//

import Foundation

/// 캐시 설정
///
/// 동영상 및 썸네일 캐시의 용량 제한과 만료 정책을 정의합니다.
struct CacheConfig {
    /// 동영상 캐시 최대 크기 (바이트)
    /// 기본값: 230MB
    let maxVideoCacheSize: Int64

    /// 썸네일 캐시 최대 크기 (바이트)
    /// 기본값: 20MB (약 200개 썸네일)
    let maxThumbnailCacheSize: Int64

    /// 메모리 캐시 최대 크기 (바이트)
    /// 기본값: 50MB
    let maxMemoryCacheSize: Int

    /// 캐시 만료 기간 (일)
    /// 기본값: 7일
    let expirationDays: Int

    /// 기본 캐시 설정
    static let `default` = CacheConfig(
        maxVideoCacheSize: 230 * 1024 * 1024,      // 230MB
        maxThumbnailCacheSize: 20 * 1024 * 1024,   // 20MB
        maxMemoryCacheSize: 50 * 1024 * 1024,      // 50MB
        expirationDays: 7
    )

    /// 캐시 설정 초기화
    /// - Parameters:
    ///   - maxVideoCacheSize: 동영상 캐시 최대 크기
    ///   - maxThumbnailCacheSize: 썸네일 캐시 최대 크기
    ///   - maxMemoryCacheSize: 메모리 캐시 최대 크기
    ///   - expirationDays: 만료 기간
    init(
        maxVideoCacheSize: Int64,
        maxThumbnailCacheSize: Int64,
        maxMemoryCacheSize: Int = 50 * 1024 * 1024,
        expirationDays: Int
    ) {
        self.maxVideoCacheSize = maxVideoCacheSize
        self.maxThumbnailCacheSize = maxThumbnailCacheSize
        self.maxMemoryCacheSize = maxMemoryCacheSize
        self.expirationDays = expirationDays
    }
}
