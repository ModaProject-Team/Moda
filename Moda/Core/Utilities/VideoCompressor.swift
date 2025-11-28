//
//  VideoCompressor.swift
//  Moda
//
//  Created by 금가경 on 11/25/25.
//

import AVFoundation
import UIKit

enum VideoCompressionError: LocalizedError {
    case invalidURL
    case compressionFailed
    case exportFailed
    case fileCreationFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "유효하지 않은 동영상 URL입니다"
        case .compressionFailed:
            return "동영상 압축에 실패했습니다"
        case .exportFailed:
            return "동영상 변환에 실패했습니다"
        case .fileCreationFailed:
            return "파일 생성에 실패했습니다"
        }
    }
}

final class VideoCompressor {
    static let shared = VideoCompressor()

    private init() {}

    /// 동영상을 10MB 이하로 자동 압축
    /// - Parameter url: 원본 동영상 URL
    /// - Returns: 압축된 동영상 URL
    func compress(url: URL) async throws -> URL {
        let asset = AVURLAsset(url: url)

        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPreset1280x720
        ) else {
            throw VideoCompressionError.compressionFailed
        }

        let outputURL = try createTemporaryURL()

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true

        await exportSession.export()

        guard exportSession.status == .completed else {
            throw VideoCompressionError.exportFailed
        }

        return outputURL
    }

    private func createTemporaryURL() throws -> URL {
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let fileName = "compressed_\(UUID().uuidString).mp4"
        let outputURL = temporaryDirectory.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        return outputURL
    }
}
