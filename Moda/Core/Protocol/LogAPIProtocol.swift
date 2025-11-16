//
//  LogAPIProtocol.swift
//  Moda
//
//  Created by 금가경 on 11/15/24.
//

import Foundation

/// 서버 로그 조회 API 프로토콜
protocol LogAPIProtocol {
    /// 서버 로그 조회
    ///
    /// - Returns: 로그 목록을 포함한 `LogResponse`
    /// - Throws: 네트워크 에러 발생 시
    func fetchLogs() async throws -> LogResponse
}
