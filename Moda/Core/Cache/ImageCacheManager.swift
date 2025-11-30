//
//  ImageCacheManager.swift
//  Moda
//
//  Created by 금가경 on 11/30/24.
//

import UIKit
import CryptoKit

/// 이미지 캐싱 매니저
///
/// 메모리 캐시와 디스크 캐시를 사용하여 이미지를 효율적으로 관리합니다.
/// Downsampling을 지원하여 메모리 사용량을 최적화합니다.
/// LRU + 시간 기반 정책으로 자동 정리됩니다.
final class ImageCacheManager: ImageCacheServiceProtocol {
    static let shared = ImageCacheManager()

    private let memoryCache: NSCache<NSString, UIImage>
    private let metadataManager: CacheMetadataManager
    private let downloadManager: ImageDownloadManager
    private let config: CacheConfig

    private let imageCacheDirectory: URL

    private init(config: CacheConfig = .default) {
        self.config = config

        // 메모리 캐시 설정
        self.memoryCache = NSCache<NSString, UIImage>()
        self.memoryCache.totalCostLimit = config.maxMemoryCacheSize

        // 디렉토리 설정
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.imageCacheDirectory = cacheDir.appendingPathComponent("Images", isDirectory: true)

        // Manager 초기화
        self.metadataManager = CacheMetadataManager()
        self.downloadManager = ImageDownloadManager()

        // 디렉토리 생성
        createDirectoriesIfNeeded()

        // 메모리 경고 옵저버 등록
        setupMemoryWarningObserver()

        // 앱 시작 시 만료된 캐시 정리
        Task {
            await clearExpiredCache()
        }
    }

    func cacheImage(from url: URL, targetSize: CGSize?) async throws -> UIImage {
        let key = cacheKey(for: url, targetSize: targetSize)

        // 메모리 캐시 확인
        if let cachedImage = memoryCache.object(forKey: key as NSString) {
            await metadataManager.updateAccessTime(for: key)
            return cachedImage
        }

        // 디스크 캐시 확인
        let fileURL = imageCacheDirectory.appendingPathComponent(key)
        if FileManager.default.fileExists(atPath: fileURL.path),
           let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            memoryCache.setObject(image, forKey: key as NSString)
            await metadataManager.updateAccessTime(for: key)
            return image
        }

        // 원본 다운로드
        let originalKey = cacheKey(for: url, targetSize: nil)
        let originalFileURL = imageCacheDirectory.appendingPathComponent(originalKey)

        // 원본이 캐시되어 있지 않으면 다운로드
        if !FileManager.default.fileExists(atPath: originalFileURL.path) {
            _ = try await downloadManager.download(from: url, to: originalFileURL)
        }

        // Downsampling 또는 원본 사용
        let image: UIImage
        if let targetSize = targetSize {
            image = try await downsample(imageAt: originalFileURL, to: targetSize, scale: UIScreen.main.scale)
        } else {
            guard let originalImage = UIImage(contentsOfFile: originalFileURL.path) else {
                throw ImageCacheError.decodingFailed
            }
            image = originalImage
        }

        // 메모리 캐시 저장
        memoryCache.setObject(image, forKey: key as NSString)

        // 디스크 캐시 저장 (downsampled 버전만)
        if targetSize != nil {
            // 알파 채널 제거 후 JPEG로 저장
            let opaqueImage = removeAlphaChannel(from: image)
            if let data = opaqueImage.jpegData(compressionQuality: 0.85) {
                try? data.write(to: fileURL)

                // 메타데이터 저장
                let metadata = CacheMetadata(
                    key: key,
                    originalURL: url.absoluteString,
                    size: Int64(data.count),
                    type: .thumbnail
                )
                await metadataManager.addOrUpdate(metadata)
            }
        }

        // 원본 이미지 메타데이터 저장
        if let originalData = try? Data(contentsOf: originalFileURL) {
            let originalMetadata = CacheMetadata(
                key: originalKey,
                originalURL: url.absoluteString,
                size: Int64(originalData.count),
                type: .thumbnail
            )
            await metadataManager.addOrUpdate(originalMetadata)
        }

        // 용량 정리
        await cleanupIfNeeded()

        return image
    }

    func getCachedImage(for url: URL, targetSize: CGSize?) -> UIImage? {
        let key = cacheKey(for: url, targetSize: targetSize)

        // 메모리 캐시 확인
        if let cachedImage = memoryCache.object(forKey: key as NSString) {
            Task {
                await metadataManager.updateAccessTime(for: key)
            }
            return cachedImage
        }

        // 디스크 캐시 확인
        let fileURL = imageCacheDirectory.appendingPathComponent(key)
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
        try? FileManager.default.removeItem(at: imageCacheDirectory)

        // 디렉토리 재생성
        createDirectoriesIfNeeded()

        // 메타데이터 삭제
        await metadataManager.removeAll()
    }

    func cleanupIfNeeded() async {
        // 만료된 캐시 정리
        await clearExpiredCache()

        // 이미지 용량 초과 정리
        let imageSize = await metadataManager.totalSize(for: .thumbnail)
        let maxImageCacheSize = config.maxThumbnailCacheSize * 10 // 이미지는 썸네일보다 큰 용량 허용 (200MB)
        if imageSize > maxImageCacheSize {
            let overSize = imageSize - maxImageCacheSize
            await removeLRUItems(size: overSize)
        }
    }

    private func clearExpiredCache() async {
        let expiredKeys = await metadataManager.expiredKeys(expirationDays: config.expirationDays)

        for key in expiredKeys {
            // 파일 삭제
            let fileURL = imageCacheDirectory.appendingPathComponent(key)
            try? FileManager.default.removeItem(at: fileURL)

            // 메모리 캐시 삭제
            memoryCache.removeObject(forKey: key as NSString)

            // 메타데이터 삭제
            await metadataManager.remove(for: key)
        }
    }

    private func removeLRUItems(size: Int64) async {
        let sortedKeys = await metadataManager.sortedByLRU(type: .thumbnail)
        var removedSize: Int64 = 0

        for key in sortedKeys {
            guard removedSize < size else { break }

            guard let metadata = await metadataManager.get(for: key) else { continue }

            // 파일 삭제
            let fileURL = imageCacheDirectory.appendingPathComponent(key)
            try? FileManager.default.removeItem(at: fileURL)

            // 메모리 캐시 삭제
            memoryCache.removeObject(forKey: key as NSString)

            // 메타데이터 삭제
            await metadataManager.remove(for: key)

            removedSize += metadata.size
        }
    }

    /// Downsampling을 사용하여 이미지를 효율적으로 로드
    /// - Parameters:
    ///   - imageURL: 이미지 파일 URL
    ///   - pointSize: 타겟 크기 (points)
    ///   - scale: 스케일 (일반적으로 UIScreen.main.scale)
    /// - Returns: 다운샘플링된 이미지
    /// - Throws: 다운샘플링 실패 시 에러
    private func downsample(imageAt imageURL: URL, to pointSize: CGSize, scale: CGFloat) throws -> UIImage {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary

        guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, imageSourceOptions) else {
            throw ImageCacheError.downsamplingFailed
        }

        let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale

        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary

        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            throw ImageCacheError.downsamplingFailed
        }

        return UIImage(cgImage: downsampledImage)
    }

    private func cacheKey(for url: URL, targetSize: CGSize?) -> String {
        var keyString = url.absoluteString

        // 타겟 크기가 있으면 키에 포함
        if let size = targetSize {
            keyString += "_\(Int(size.width))x\(Int(size.height))"
        }

        let hash = SHA256.hash(data: Data(keyString.utf8))
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        return "\(hashString).jpg"
    }

    private func createDirectoriesIfNeeded() {
        try? FileManager.default.createDirectory(
            at: imageCacheDirectory,
            withIntermediateDirectories: true
        )
    }

    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    @objc private func handleMemoryWarning() {
        clearMemoryCache()
    }

    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }

    func cancelImageDownload(for url: URL) async {
        await downloadManager.cancelDownload(for: url)
    }

    func cancelAllDownloads() async {
        await downloadManager.cancelAllDownloads()
    }

    func prefetchImages(urls: [URL], targetSize: CGSize?) {
        Task(priority: .low) {
            for url in urls {
                // 이미 캐시된 경우 스킵
                guard getCachedImage(for: url, targetSize: targetSize) == nil else { continue }

                do {
                    _ = try await cacheImage(from: url, targetSize: targetSize)
                } catch {
                    // Prefetch 실패는 무시
                }
            }
        }
    }

    /// 이미지에서 알파 채널 제거
    /// - Parameter image: 원본 이미지
    /// - Returns: 알파 채널이 제거된 이미지
    private func removeAlphaChannel(from image: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = image.scale

        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { context in
            image.draw(at: .zero)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
