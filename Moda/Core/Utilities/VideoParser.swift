//
//  VideoParser.swift
//  Moda
//
//  Created by 금가경 on 12/06/25.
//

import AVFoundation
import UIKit

enum VideoParserError: LocalizedError {
    case invalidURL
    case assetLoadFailed
    case trackLoadFailed
    case metadataExtractionFailed
    case thumbnailGenerationFailed
    case fileSizeExceeded

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 비디오 URL입니다"
        case .assetLoadFailed:
            return "비디오 파일을 불러올 수 없습니다"
        case .trackLoadFailed:
            return "비디오 트랙을 불러올 수 없습니다"
        case .metadataExtractionFailed:
            return "비디오 정보 추출에 실패했습니다"
        case .thumbnailGenerationFailed:
            return "썸네일 생성에 실패했습니다"
        case .fileSizeExceeded:
            return "동영상 파일이 10MB를 초과했습니다"
        }
    }
}

struct VideoMetadata {
    let duration: CMTime
    let size: CGSize
    let frameRate: Float
    let bitRate: Float
    let codec: String?
    let hasAudio: Bool
    let fileSize: Int64?
}

final class VideoParser {
    static let shared = VideoParser()

    private init() {}

    /// 비디오 메타데이터 추출
    func parseMetadata(from url: URL) async throws -> VideoMetadata {
        let asset = AVURLAsset(url: url)

        // 비디오 트랙 로드
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw VideoParserError.trackLoadFailed
        }

        // 오디오 트랙 확인
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)

        // 메타데이터 추출
        let duration = try await asset.load(.duration)
        let naturalSize = try await videoTrack.load(.naturalSize)
        let preferredTransform = try await videoTrack.load(.preferredTransform)
        let nominalFrameRate = try await videoTrack.load(.nominalFrameRate)
        let estimatedDataRate = try await videoTrack.load(.estimatedDataRate)

        // 회전 보정된 실제 크기
        let actualSize = getActualSize(naturalSize: naturalSize, transform: preferredTransform)

        // 코덱 정보
        let formatDescriptions = try await videoTrack.load(.formatDescriptions)
        let codec = formatDescriptions.first.flatMap {
            CMFormatDescriptionGetMediaSubType($0)
        }.map { fourCharCodeToString($0) }

        // 파일 크기
        let fileSize = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64

        return VideoMetadata(
            duration: duration,
            size: actualSize,
            frameRate: nominalFrameRate,
            bitRate: estimatedDataRate,
            codec: codec,
            hasAudio: !audioTracks.isEmpty,
            fileSize: fileSize
        )
    }

    /// 썸네일 생성
    func generateThumbnail(
        from url: URL,
        at time: CMTime = .zero,
        size: CGSize? = nil
    ) async throws -> UIImage {
        let asset = AVURLAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        if let size = size {
            imageGenerator.maximumSize = size
        }

        do {
            let cgImage = try await imageGenerator.image(at: time).image
            return UIImage(cgImage: cgImage)
        } catch {
            throw VideoParserError.thumbnailGenerationFailed
        }
    }

    /// 여러 썸네일 생성 (타임라인용)
    func generateThumbnails(
        from url: URL,
        count: Int,
        size: CGSize? = nil
    ) async throws -> [UIImage] {
        let metadata = try await parseMetadata(from: url)
        let duration = metadata.duration.seconds
        let interval = duration / Double(count)

        var thumbnails: [UIImage] = []

        for i in 0..<count {
            let time = CMTime(seconds: interval * Double(i), preferredTimescale: 600)
            let thumbnail = try await generateThumbnail(from: url, at: time, size: size)
            thumbnails.append(thumbnail)
        }

        return thumbnails
    }

    /// 비디오 유효성 검증
    func validate(url: URL, maxDuration: TimeInterval? = nil, maxFileSize: Int64 = 10 * 1024 * 1024) async throws -> Bool {
        let metadata = try await parseMetadata(from: url)

        // 길이 검증
        if let maxDuration = maxDuration {
            guard metadata.duration.seconds <= maxDuration else {
                throw VideoParserError.metadataExtractionFailed
            }
        }

        // 파일 크기 검증 (기본 10MB)
        if let fileSize = metadata.fileSize {
            guard fileSize <= maxFileSize else {
                throw VideoParserError.fileSizeExceeded
            }
        }

        return true
    }

    private func getActualSize(naturalSize: CGSize, transform: CGAffineTransform) -> CGSize {
        if transform.a == 0 && abs(transform.b) == 1.0 && abs(transform.c) == 1.0 && transform.d == 0 {
            return CGSize(width: naturalSize.height, height: naturalSize.width)
        }
        return naturalSize
    }

    private func fourCharCodeToString(_ code: FourCharCode) -> String {
        let bytes: [UInt8] = [
            UInt8((code >> 24) & 0xFF),
            UInt8((code >> 16) & 0xFF),
            UInt8((code >> 8) & 0xFF),
            UInt8(code & 0xFF)
        ]
        return String(bytes: bytes, encoding: .ascii) ?? "unknown"
    }
}
