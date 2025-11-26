//
//  VideoThumbnailGenerator.swift
//  Moda
//
//  Created by Suji Jang on 11/26/25.
//

import AVFoundation
import UIKit

enum VideoThumbnailError: LocalizedError {
    case invalidURL
    case thumbnailGenerationFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "유효하지 않은 동영상 URL입니다"
        case .thumbnailGenerationFailed:
            return "썸네일 생성에 실패했습니다"
        }
    }
}

final class VideoThumbnailGenerator {
    static let shared = VideoThumbnailGenerator()

    private init() {}

    /// 동영상 URL에서 썸네일 이미지 생성
    /// - Parameters:
    ///   - url: 동영상 URL
    ///   - time: 썸네일을 추출할 시간 (기본값: 0초)
    /// - Returns: 생성된 썸네일 UIImage
    func generateThumbnail(from url: URL, at time: CMTime = .zero) async throws -> UIImage {
        let asset = AVURLAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceAfter = .zero
        imageGenerator.requestedTimeToleranceBefore = .zero

        do {
            let cgImage = try await imageGenerator.image(at: time).image
            return UIImage(cgImage: cgImage)
        } catch {
            print("썸네일 생성 실패: \(error.localizedDescription)")
            throw VideoThumbnailError.thumbnailGenerationFailed
        }
    }

    /// 로컬 파일 경로에서 썸네일 생성
    /// - Parameter path: 로컬 동영상 파일 경로
    /// - Returns: 생성된 썸네일 UIImage
    func generateThumbnail(from path: String) async throws -> UIImage {
        let url = URL(fileURLWithPath: path)
        return try await generateThumbnail(from: url)
    }
}

extension String {
    /// 파일 URL이 동영상인지 확인
    var isVideoFile: Bool {
        let videoExtensions = ["mp4", "mov", "m4v", "avi", "mpg", "mpeg", "wmv", "flv", "webm"]
        let ext = (self as NSString).pathExtension.lowercased()
        return videoExtensions.contains(ext)
    }

    /// 파일 URL이 이미지인지 확인
    var isImageFile: Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "heic", "heif", "webp", "bmp", "tiff"]
        let ext = (self as NSString).pathExtension.lowercased()
        return imageExtensions.contains(ext)
    }
}
