//
//  VideoCacheError.swift
//  Moda
//
//  Created by 금가경 on 11/30/24.
//

import Foundation

/// 동영상 캐싱 관련 에러
enum VideoCacheError: LocalizedError {
    case downloadFailed
    case thumbnailGenerationFailed
    case diskWriteFailed
    case insufficientStorage
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .downloadFailed:
            return "동영상 다운로드에 실패했습니다"
        case .thumbnailGenerationFailed:
            return "썸네일 생성에 실패했습니다"
        case .diskWriteFailed:
            return "파일 저장에 실패했습니다"
        case .insufficientStorage:
            return "저장 공간이 부족합니다"
        case .invalidURL:
            return "잘못된 URL입니다"
        }
    }
}
