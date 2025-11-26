//
//  ChatAPI.swift
//  Moda
//
//  Created by hyunMac on 11/24/25.
//

import Foundation

final class ChatAPI: ChatAPIProtocol {
    static let shared = ChatAPI()

    private let networkService: NetworkServiceProtocol

    private init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
    }

    func getOrCreateRoom(opponentId: String) async throws -> ChatRoomResponse {
        try await networkService.request(
            endpoint: ChatRouter.getOrCreateRoom(opponentId: opponentId),
            responseType: ChatRoomResponse.self
        )
    }

    func getRooms() async throws -> ChatRoomListResponse {
        try await networkService.request(
            endpoint: ChatRouter.getRooms,
            responseType: ChatRoomListResponse.self
        )
    }

    func sendMessage(roomId: String, content: String?, files: [String]?) async throws -> ChatMessageResponse {
        try await networkService.request(
            endpoint: ChatRouter.sendMessage(roomId: roomId, content: content, files: files),
            responseType: ChatMessageResponse.self
        )
    }

    func getMessages(roomId: String, cursorDate: String?) async throws -> ChatHistoryResponse {
        try await networkService.request(
            endpoint: ChatRouter.getMessages(roomId: roomId, cursorDate: cursorDate),
            responseType: ChatHistoryResponse.self
        )
    }

    // NEW
    func uploadFiles(roomId: String, files: [FileData]) async throws -> ChatFileUploadResponse {
        let endpoint = ChatRouter.uploadFiles(roomId: roomId, files: files)

        guard let multipart = endpoint.multipartData() else {
            throw NetworkError.invalidURL
        }

        var request = try endpoint.asURLRequest()
        request.setValue("multipart/form-data; boundary=\(multipart.boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = multipart.data

        // NetworkService를 그대로 쓰지 않고 직접 전송하는 패턴은 PostAPI와 동일하게 맞춥니다.
        let (data, urlResponse) = try await URLSession.shared.data(for: request)

        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        // 공통 에러 처리 규칙에 맞춰 상태 코드 처리
        if let error = NetworkService.shared.handleHTTPStatusForPublicUse(httpResponse.statusCode, data: data) {
            throw error
        }

        return try JSONDecoder().decode(ChatFileUploadResponse.self, from: data)
    }
}

// NetworkService의 상태코드 핸들러를 재사용하기 위해 internal helper를 노출하거나,
// 아래와 같이 파일 내부에서만 쓰는 확장을 둘 수 있습니다.
private extension NetworkService {
    func handleHTTPStatusForPublicUse(_ statusCode: Int, data: Data) -> NetworkError? {
        // 기존 private handleHTTPStatusCode를 복제
        switch statusCode {
        case 200...299:
            return nil
        case 419:
            return .tokenExpired
        case 418:
            let errorMessage = parseErrorMessageForPublicUse(from: data)
            return .serverError(message: errorMessage)
        case 400...499:
            let errorMessage = parseErrorMessageForPublicUse(from: data)
            return .serverError(message: errorMessage)
        case 500...599:
            return .internalServerError
        default:
            return .unknown
        }
    }

    func parseErrorMessageForPublicUse(from data: Data) -> String {
        // ErrorResponse 디코딩 시도
        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            return errorResponse.message
        }
        return "알 수 없는 오류가 발생했습니다"
    }
}
