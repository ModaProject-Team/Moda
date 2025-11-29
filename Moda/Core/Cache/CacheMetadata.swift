//
//  CacheMetadata.swift
//  Moda
//
//  Created by 금가경 on 11/30/24.
//

import Foundation

/// 캐시 파일의 메타데이터를 나타내는 모델
///
/// 캐시된 동영상 및 썸네일 파일의 정보를 추적합니다.
/// LRU 정책과 시간 기반 만료 정책에 사용됩니다.
struct CacheMetadata: Codable {
    /// 캐시 키 (파일명)
    let key: String

    /// 원본 URL
    let originalURL: String

    /// 파일 크기 (바이트)
    let size: Int64

    /// 생성 시간 (시간 기반 만료용)
    let createdAt: Date

    /// 마지막 접근 시간 (LRU용)
    var lastAccessedAt: Date

    /// 캐시 타입 (동영상 또는 썸네일)
    let type: CacheType

    /// 캐시 파일 타입
    enum CacheType: String, Codable {
        case video
        case thumbnail
    }

    /// 메타데이터 초기화
    /// - Parameters:
    ///   - key: 캐시 키
    ///   - originalURL: 원본 URL
    ///   - size: 파일 크기
    ///   - type: 캐시 타입
    init(key: String, originalURL: String, size: Int64, type: CacheType) {
        self.key = key
        self.originalURL = originalURL
        self.size = size
        self.createdAt = Date()
        self.lastAccessedAt = Date()
        self.type = type
    }

    /// 접근 시간 업데이트
    mutating func updateAccessTime() {
        self.lastAccessedAt = Date()
    }

    /// 만료 여부 확인
    /// - Parameter expirationDays: 만료 기간 (일)
    /// - Returns: 만료 여부
    func isExpired(expirationDays: Int) -> Bool {
        let expirationDate = Calendar.current.date(byAdding: .day, value: expirationDays, to: createdAt)
        return Date() > (expirationDate ?? createdAt)
    }
}
