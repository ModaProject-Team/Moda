//
//  VideoCacheManager.swift
//  Moda
//
//  Created by 금가경 on 11/30/24.
//

import UIKit
import AVFoundation
import CryptoKit

/// 동영상 및 썸네일 캐싱 매니저
///
/// 메모리 캐시와 디스크 캐시를 사용하여 동영상과 썸네일을 효율적으로 관리합니다.
/// LRU + 시간 기반 정책으로 자동 정리됩니다.
final class VideoCacheManager: VideoCacheServiceProtocol {
    static let shared = VideoCacheManager()

    private let memoryCache: NSCache<NSString, AnyObject>
    private let metadataManager: CacheMetadataManager
    private let downloadManager: VideoDownloadManager
    private let config: CacheConfig

    private let videoCacheDirectory: URL
    private let thumbnailCacheDirectory: URL

    private init(config: CacheConfig = .default) {
        self.config = config

        // 메모리 캐시 설정
        self.memoryCache = NSCache<NSString, AnyObject>()
        self.memoryCache.totalCostLimit = config.maxMemoryCacheSize

        // 디렉토리 설정
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.videoCacheDirectory = cacheDir.appendingPathComponent("Videos", isDirectory: true)
        self.thumbnailCacheDirectory = cacheDir.appendingPathComponent("Thumbnails", isDirectory: true)

        // Manager 초기화
        self.metadataManager = CacheMetadataManager()
        self.downloadManager = VideoDownloadManager()

        // 디렉토리 생성
        createDirectoriesIfNeeded()

        // 앱 시작 시 만료된 캐시 정리
        Task {
            await clearExpiredCache()
        }
    }

    func cacheVideo(from url: URL) async throws -> URL {
        // 이미 캐시된 경우
        if let cachedURL = getCachedVideo(for: url) {
            await metadataManager.updateAccessTime(for: cacheKey(for: url))
            return cachedURL
        }

        // 다운로드
        let key = cacheKey(for: url)
        let destinationURL = videoCacheDirectory.appendingPathComponent(key)

        let localURL = try await downloadManager.download(from: url, to: destinationURL)

        // 메타데이터 저장
        let fileSize = try FileManager.default.attributesOfItem(atPath: localURL.path)[.size] as? Int64 ?? 0
        let metadata = CacheMetadata(
            key: key,
            originalURL: url.absoluteString,
            size: fileSize,
            type: .video
        )
        await metadataManager.addOrUpdate(metadata)

        // 용량 정리
        await cleanupIfNeeded()

        return localURL
    }

    func getCachedVideo(for url: URL) -> URL? {
        let key = cacheKey(for: url)
        let fileURL = videoCacheDirectory.appendingPathComponent(key)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        Task {
            await metadataManager.updateAccessTime(for: key)
        }

        return fileURL
    }

    func cacheThumbnail(from videoURL: URL) async throws -> UIImage {
        let key = thumbnailKey(for: videoURL)

        // 메모리 캐시 확인
        if let cachedImage = memoryCache.object(forKey: key as NSString) as? UIImage {
            await metadataManager.updateAccessTime(for: key)
            return cachedImage
        }

        // 디스크 캐시 확인
        let fileURL = thumbnailCacheDirectory.appendingPathComponent(key)
        if FileManager.default.fileExists(atPath: fileURL.path),
           let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            memoryCache.setObject(image, forKey: key as NSString)
            await metadataManager.updateAccessTime(for: key)
            return image
        }

        // 썸네일 생성
        let thumbnail = try await generateThumbnail(from: videoURL)

        // 최적화 (300pt, JPEG 0.8)
        let optimized = optimizeThumbnail(thumbnail)

        // 메모리 캐시 저장
        memoryCache.setObject(optimized, forKey: key as NSString)

        // 디스크 캐시 저장
        if let data = optimized.jpegData(compressionQuality: 0.8) {
            try? data.write(to: fileURL)

            // 메타데이터 저장
            let metadata = CacheMetadata(
                key: key,
                originalURL: videoURL.absoluteString,
                size: Int64(data.count),
                type: .thumbnail
            )
            await metadataManager.addOrUpdate(metadata)
        }

        // 용량 정리
        await cleanupIfNeeded()

        return optimized
    }

    func getCachedThumbnail(for url: URL) -> UIImage? {
        let key = thumbnailKey(for: url)

        // 메모리 캐시 확인
        if let cachedImage = memoryCache.object(forKey: key as NSString) as? UIImage {
            Task {
                await metadataManager.updateAccessTime(for: key)
            }
            return cachedImage
        }

        // 디스크 캐시 확인
        let fileURL = thumbnailCacheDirectory.appendingPathComponent(key)
        if FileManager.default.fileExists(atPath: fileURL.path),
           let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            memoryCache.setObject(image, forKey: key as NSString)
            Task {
                await metadataManager.updateAccessTime(for: key)
            }
            return image
        }

        return nil
    }

    func clearCache() async {
        // 메모리 캐시 삭제
        memoryCache.removeAllObjects()

        // 디스크 캐시 삭제
        try? FileManager.default.removeItem(at: videoCacheDirectory)
        try? FileManager.default.removeItem(at: thumbnailCacheDirectory)

        // 디렉토리 재생성
        createDirectoriesIfNeeded()

        // 메타데이터 삭제
        await metadataManager.removeAll()
    }

    func cleanupIfNeeded() async {
        // 만료된 캐시 정리
        await clearExpiredCache()

        // 동영상 용량 초과 정리
        let videoSize = await metadataManager.totalSize(for: .video)
        if videoSize > config.maxVideoCacheSize {
            let overSize = videoSize - config.maxVideoCacheSize
            await removeLRUItems(size: overSize, type: .video)
        }

        // 썸네일 용량 초과 정리
        let thumbnailSize = await metadataManager.totalSize(for: .thumbnail)
        if thumbnailSize > config.maxThumbnailCacheSize {
            let overSize = thumbnailSize - config.maxThumbnailCacheSize
            await removeLRUItems(size: overSize, type: .thumbnail)
        }
    }

    private func clearExpiredCache() async {
        let expiredKeys = await metadataManager.expiredKeys(expirationDays: config.expirationDays)

        for key in expiredKeys {
            // 파일 삭제
            let videoURL = videoCacheDirectory.appendingPathComponent(key)
            let thumbnailURL = thumbnailCacheDirectory.appendingPathComponent(key)

            try? FileManager.default.removeItem(at: videoURL)
            try? FileManager.default.removeItem(at: thumbnailURL)

            // 메모리 캐시 삭제
            memoryCache.removeObject(forKey: key as NSString)

            // 메타데이터 삭제
            await metadataManager.remove(for: key)
        }
    }

    private func removeLRUItems(size: Int64, type: CacheMetadata.CacheType) async {
        let sortedKeys = await metadataManager.sortedByLRU(type: type)
        var removedSize: Int64 = 0

        for key in sortedKeys {
            guard removedSize < size else { break }

            guard let metadata = await metadataManager.get(for: key) else { continue }

            // 파일 삭제
            let directory = type == .video ? videoCacheDirectory : thumbnailCacheDirectory
            let fileURL = directory.appendingPathComponent(key)
            try? FileManager.default.removeItem(at: fileURL)

            // 메모리 캐시 삭제
            memoryCache.removeObject(forKey: key as NSString)

            // 메타데이터 삭제
            await metadataManager.remove(for: key)

            removedSize += metadata.size
        }
    }

    private func generateThumbnail(from url: URL) async throws -> UIImage {
        let asset = AVURLAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        let cgImage = try await imageGenerator.image(at: .zero).image

        return UIImage(cgImage: cgImage)
    }

    private func optimizeThumbnail(_ image: UIImage) -> UIImage {
        let maxSize: CGFloat = 300

        let size = image.size
        let scale = min(maxSize / size.width, maxSize / size.height)

        if scale >= 1.0 {
            return image
        }

        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 2.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resized ?? image
    }

    private func cacheKey(for url: URL) -> String {
        let hash = SHA256.hash(data: Data(url.absoluteString.utf8))
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        let ext = (url.lastPathComponent as NSString).pathExtension
        return "\(hashString).\(ext)"
    }

    private func thumbnailKey(for url: URL) -> String {
        let hash = SHA256.hash(data: Data(url.absoluteString.utf8))
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        return "\(hashString).jpg"
    }

    private func createDirectoriesIfNeeded() {
        try? FileManager.default.createDirectory(
            at: videoCacheDirectory,
            withIntermediateDirectories: true
        )
        try? FileManager.default.createDirectory(
            at: thumbnailCacheDirectory,
            withIntermediateDirectories: true
        )
    }
}
