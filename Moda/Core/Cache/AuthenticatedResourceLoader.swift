//
//  AuthenticatedResourceLoader.swift
//  Moda
//
//  Created by 금가경 on 11/30/24.
//

import AVFoundation
import Foundation

/// AVAsset의 리소스 로딩을 관리하며 인증 헤더를 추가합니다.
///
/// 206 Partial Content 요청을 지원하며,
/// SesacKey, ProductId, Authorization 헤더를 자동으로 추가합니다.
final class AuthenticatedResourceLoader: NSObject, AVAssetResourceLoaderDelegate {
    private var pendingRequests: [AVAssetResourceLoadingRequest: URLSessionDataTask] = [:]
    private let session: URLSession

    override init() {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: configuration)
        super.init()
    }

    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        guard let url = loadingRequest.request.url else {
            return false
        }

        // Custom scheme을 실제 https로 변환
        let actualURL = convertToActualURL(url)

        var request = URLRequest(url: actualURL)
        request.setValue(NetworkConfig.sesacKey, forHTTPHeaderField: "SesacKey")
        request.setValue(NetworkConfig.productId, forHTTPHeaderField: "ProductId")
        request.setValue(TokenManager.shared.accessToken ?? "", forHTTPHeaderField: "Authorization")

        // Range 헤더 추가 (206 Partial Content 요청)
        if let dataRequest = loadingRequest.dataRequest {
            let requestedOffset = dataRequest.requestedOffset
            let requestedLength = dataRequest.requestedLength

            var rangeEnd = ""
            if dataRequest.requestsAllDataToEndOfResource {
                rangeEnd = ""
            } else {
                rangeEnd = "\(requestedOffset + Int64(requestedLength) - 1)"
            }

            request.setValue("bytes=\(requestedOffset)-\(rangeEnd)", forHTTPHeaderField: "Range")
        }

        let task = session.dataTask(with: request) { [weak self, weak loadingRequest] data, response, error in
            guard let self = self, let loadingRequest = loadingRequest else { return }

            defer {
                self.pendingRequests.removeValue(forKey: loadingRequest)
            }

            if let error = error {
                loadingRequest.finishLoading(with: error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                loadingRequest.finishLoading(with: VideoCacheError.downloadFailed)
                return
            }

            // 206 Partial Content 또는 200 OK 모두 허용
            guard (200...299).contains(httpResponse.statusCode) else {
                loadingRequest.finishLoading(with: VideoCacheError.downloadFailed)
                return
            }

            // Content-Type 정보 설정
            if let contentType = httpResponse.mimeType {
                loadingRequest.contentInformationRequest?.contentType = contentType
            }

            // Content-Length 설정 (전체 파일 크기)
            if let contentRangeHeader = httpResponse.allHeaderFields["Content-Range"] as? String {
                // "bytes 0-1023/123456" 형식에서 전체 크기 추출
                if let totalSize = contentRangeHeader.split(separator: "/").last,
                   let size = Int64(totalSize) {
                    loadingRequest.contentInformationRequest?.contentLength = size
                }
            } else {
                let contentLength = httpResponse.expectedContentLength
                if contentLength > 0 {
                    loadingRequest.contentInformationRequest?.contentLength = contentLength
                }
            }

            loadingRequest.contentInformationRequest?.isByteRangeAccessSupported = true

            // 데이터 제공
            if let data = data {
                loadingRequest.dataRequest?.respond(with: data)
            }

            loadingRequest.finishLoading()
        }

        pendingRequests[loadingRequest] = task
        task.resume()

        return true
    }

    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        didCancel loadingRequest: AVAssetResourceLoadingRequest
    ) {
        pendingRequests[loadingRequest]?.cancel()
        pendingRequests.removeValue(forKey: loadingRequest)
    }

    /// Custom scheme을 실제 HTTPS URL로 변환
    /// - Parameter url: custom-scheme://... 형식의 URL
    /// - Returns: https://... 형식의 실제 URL
    private func convertToActualURL(_ url: URL) -> URL {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.scheme = "https"
        return components?.url ?? url
    }

    /// 모든 대기 중인 요청 취소
    func cancelAllRequests() {
        pendingRequests.values.forEach { $0.cancel() }
        pendingRequests.removeAll()
    }

    deinit {
        cancelAllRequests()
    }
}
