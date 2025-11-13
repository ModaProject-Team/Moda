//
//  LogService.swift
//  Moda
//
//  Created by 금가경 on 11/13/24.
//

import Foundation

/// 서버 로그 조회 서비스
///
/// 디버깅을 위한 서버 로그 조회 기능을 제공합니다.
final class LogService {
    /// 싱글톤 인스턴스
    static let shared = LogService()

    private let networkService: NetworkServiceProtocol

    /// LogService 초기화
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
        let endpoint = APIRouter.getLogs
        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: LogResponse.self
        )

        return response
    }
}
