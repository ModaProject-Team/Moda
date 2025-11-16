//
//  LogAPI.swift
//  Moda
//
//  Created by 금가경 on 11/13/24.
//

import Foundation

/// 서버 로그 조회 API 통신을 처리하는 클래스
///
/// 디버깅을 위한 서버 로그 조회 API 호출을 제공합니다.
final class LogAPI: LogAPIProtocol {
    /// 싱글톤 인스턴스
    static let shared = LogAPI()

    private let networkService: NetworkServiceProtocol

    /// LogAPI 초기화
    ///
    /// - Parameter networkService: 네트워크 서비스 인스턴스
    private init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
    }

    /// 서버 로그 조회
    ///
    /// 서버에 기록된 API 요청 로그를 조회합니다.
    ///
    /// - Returns: 로그 목록을 포함한 `LogResponse`
    /// - Throws: 네트워크 에러 발생 시
    func fetchLogs() async throws -> LogResponse {
        let endpoint = LogRouter.getLogs
        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: LogResponse.self
        )

        return response
    }
}
