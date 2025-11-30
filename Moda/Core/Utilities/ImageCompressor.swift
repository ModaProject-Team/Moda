//
//  ImageCompressor.swift
//  Moda
//
//  Created by 금가경 on 11/25/25.
//

import UIKit
import UniformTypeIdentifiers

enum ImageCompressionError: LocalizedError {
    case compressionFailed
    case unsupportedFormat

    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "이미지 압축에 실패했습니다"
        case .unsupportedFormat:
            return "지원하지 않는 이미지 포맷입니다"
        }
    }
}

final class ImageCompressor {
    static let shared = ImageCompressor()

    private init() {}

    /// 이미지를 지정된 용량 이하로 압축
    ///
    /// 전략:
    /// 1. HEIC/JPEG: 원본 포맷 유지하며 압축
    /// 2. PNG: PNG로 압축 시도 후 용량 초과 시 JPEG로 변환
    /// 3. 압축 품질 조정으로도 용량 초과 시 이미지 리사이징
    ///
    /// - Parameters:
    ///   - image: 압축할 이미지
    ///   - maxSizeInKB: 최대 용량 (KB)
    /// - Returns: 압축된 이미지 데이터와 포맷 정보
    func compress(
        image: UIImage,
        maxSizeInKB: Int
    ) -> (data: Data, format: ImageFormat)? {
        let maxSizeInBytes = maxSizeInKB * 1024

        // 1. HEIC 포맷 시도 (가장 효율적)
        if let heicData = image.heicData(compressionQuality: 0.8),
           heicData.count <= maxSizeInBytes {
            return (heicData, .heic)
        }

        // 2. HEIC로 압축 시도
        if let compressedHEIC = compressHEIC(image, maxSizeInBytes: maxSizeInBytes) {
            return (compressedHEIC, .heic)
        }

        // 3. PNG로 압축 시도 (투명도가 있을 수 있음)
        if let pngData = image.pngData(),
           pngData.count <= maxSizeInBytes {
            return (pngData, .png)
        }

        // 4. JPEG로 압축 시도
        if let jpegData = compressJPEG(image, maxSizeInBytes: maxSizeInBytes) {
            return (jpegData, .jpeg)
        }

        // 5. 리사이징 후 JPEG 압축
        if let resizedData = resizeAndCompress(image, maxSizeInBytes: maxSizeInBytes) {
            return (resizedData, .jpeg)
        }

        return nil
    }

    /// HEIC 포맷으로 압축
    private func compressHEIC(_ image: UIImage, maxSizeInBytes: Int) -> Data? {
        var compression: CGFloat = 0.8

        while compression > 0.1 {
            if let data = image.heicData(compressionQuality: compression),
               data.count <= maxSizeInBytes {
                return data
            }
            compression -= 0.1
        }

        return nil
    }

    /// JPEG 포맷으로 압축
    private func compressJPEG(_ image: UIImage, maxSizeInBytes: Int) -> Data? {
        // 알파 채널 제거
        let opaqueImage = removeAlphaChannel(from: image)

        var compression: CGFloat = 0.8

        while compression > 0.1 {
            if let data = opaqueImage.jpegData(compressionQuality: compression),
               data.count <= maxSizeInBytes {
                return data
            }
            compression -= 0.1
        }

        return nil
    }

    /// 이미지 크기를 줄인 후 JPEG로 압축
    private func resizeAndCompress(_ image: UIImage, maxSizeInBytes: Int) -> Data? {
        var scale: CGFloat = 0.8

        while scale > 0.3 {
            let newSize = CGSize(
                width: image.size.width * scale,
                height: image.size.height * scale
            )

            if let resized = resize(image: image, to: newSize),
               let data = compressJPEG(resized, maxSizeInBytes: maxSizeInBytes) {
                return data
            }

            scale -= 0.1
        }

        return nil
    }

    /// 이미지 리사이징
    private func resize(image: UIImage, to newSize: CGSize) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = image.scale

        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: newSize))
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
}

// MARK: - Image Format

enum ImageFormat {
    case heic
    case jpeg
    case png

    var mimeType: String {
        switch self {
        case .heic:
            return "image/heic"
        case .jpeg:
            return "image/jpeg"
        case .png:
            return "image/png"
        }
    }

    var fileExtension: String {
        switch self {
        case .heic:
            return "heic"
        case .jpeg:
            return "jpg"
        case .png:
            return "png"
        }
    }
}

// MARK: - UIImage Extension for HEIC

extension UIImage {
    /// UIImage를 HEIC 포맷으로 변환
    func heicData(compressionQuality: CGFloat = 1.0) -> Data? {
        guard let cgImage = self.cgImage else { return nil }

        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data as CFMutableData,
            UTType.heic.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality
        ]

        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }

        return data as Data
    }
}
