//
//  VideoDownloadManager.swift
//  Moda
//
//  Created by 금가경 on 11/30/24.
//

import Foundation

/// 동영상 다운로드 관리자
///
/// actor로 구현되어 스레드 안전성을 보장하며,
/// 중복 다운로드를 방지합니다.
actor VideoDownloadManager {
    private var downloadTasks: [URL: Task<URL, Error>] = [:]

    /// 동영상 다운로드
    /// - Parameters:
    ///   - url: 원본 URL
    ///   - destinationURL: 저장할 로컬 URL
    /// - Returns: 저장된 파일의 로컬 URL
    /// - Throws: 다운로드 실패 시 에러
    func download(from url: URL, to destinationURL: URL) async throws -> URL {
        // 중복 다운로드 방지
        if let existingTask = downloadTasks[url] {
            return try await existingTask.value
        }

        let task = Task<URL, Error> {
            // 인증 헤더 추가
            var request = URLRequest(url: url)
            request.setValue(NetworkConfig.sesacKey, forHTTPHeaderField: "SesacKey")
            request.setValue(NetworkConfig.productId, forHTTPHeaderField: "ProductId")
            request.setValue(TokenManager.shared.accessToken ?? "", forHTTPHeaderField: "Authorization")

            // 다운로드
            let (tempURL, response) = try await URLSession.shared.download(for: request)

            // 응답 검증
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw VideoCacheError.downloadFailed
            }

            // 디렉토리 생성
            let directory = destinationURL.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: directory.path) {
                try FileManager.default.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true
                )
            }

            // 기존 파일 삭제
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            // 파일 이동
            try FileManager.default.moveItem(at: tempURL, to: destinationURL)

            // Task 정리
            await cleanupTask(for: url)

            return destinationURL
        }

        downloadTasks[url] = task

        do {
            return try await task.value
        } catch {
            await cleanupTask(for: url)
            throw error
        }
    }

    /// Task 정리
    /// - Parameter url: 원본 URL
    private func cleanupTask(for url: URL) {
        downloadTasks.removeValue(forKey: url)
    }

    /// 진행 중인 다운로드 취소
    /// - Parameter url: 원본 URL
    func cancelDownload(for url: URL) {
        downloadTasks[url]?.cancel()
        downloadTasks.removeValue(forKey: url)
    }

    /// 모든 다운로드 취소
    func cancelAllDownloads() {
        downloadTasks.values.forEach { $0.cancel() }
        downloadTasks.removeAll()
    }
}
