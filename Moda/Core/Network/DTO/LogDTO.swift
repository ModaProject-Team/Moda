//
//  LogDTO.swift
//  Moda
//
//  Created by 금가경 on 11/13/24.
//

import Foundation

// MARK: - 로그 조회
struct LogResponse: Decodable {
    let count: Int

    let logs: [Log]
}

struct Log: Decodable, Identifiable {
    let date: String
    let name: String
    let method: String
    let routePath: String
    let body: String
    let statusCode: String

    var id: String { date + routePath }

    enum CodingKeys: String, CodingKey {
        case date
        case name
        case method
        case routePath = "route_path"
        case body
        case statusCode = "status_code"
    }
}
