//
//  NetworkServiceProtocol.swift
//  Moda
//
//  Created by 금가경 on 11/12/24.
//

import Foundation

protocol NetworkServiceProtocol {
    func request<T: Decodable>(
        endpoint: Endpoint,
        responseType: T.Type
    ) async throws -> T

    func requestWithoutResponse(endpoint: Endpoint) async throws
}
