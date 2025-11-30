//
//  ImageCacheError.swift
//  Moda
//
//  Created by 금가경 on 11/30/24.
//

import Foundation

/// 이미지 캐싱 관련 에러
enum ImageCacheError: LocalizedError {
    case downloadFailed
    case decodingFailed
    case downsamplingFailed
    case diskWriteFailed
    case insufficientStorage
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .downloadFailed:
            return "이미지 다운로드에 실패했습니다"
        case .decodingFailed:
            return "이미지 디코딩에 실패했습니다"
        case .downsamplingFailed:
            return "이미지 다운샘플링에 실패했습니다"
        case .diskWriteFailed:
            return "파일 저장에 실패했습니다"
        case .insufficientStorage:
            return "저장 공간이 부족합니다"
        case .invalidURL:
            return "잘못된 URL입니다"
        }
    }
}
