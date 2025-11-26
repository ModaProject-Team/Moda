//
//  ChatRouter.swift
//  Moda
//
//  Created by hyunMac on 11/24/25.
//

import Foundation

/// 채팅 관련 API 엔드포인트
enum ChatRouter {

    /// 채팅방 생성 또는 조회 (상대방과의 1:1 방)
    case getOrCreateRoom(opponentId: String)

    /// 채팅방 리스트 조회
    case getRooms

    /// 채팅 보내기
    case sendMessage(roomId: String, content: String?, files: [String]?)

    /// 채팅 내역 리스트 조회
    case getMessages(roomId: String, cursorDate: String?)

    /// 채팅 파일 업로드 (multipart/form-data)
    case uploadFiles(roomId: String, files: [FileData])
}

extension ChatRouter: Endpoint {

    var baseURL: String {
        return NetworkConfig.baseURL
    }

    var path: String {
        let basePath = "/v1/chats"

        switch self {
        case .getOrCreateRoom, .getRooms:
            return basePath
        case .sendMessage(let roomId, _, _), .getMessages(let roomId, _):
            return "\(basePath)/\(roomId)"
        case .uploadFiles(let roomId, _):
            return "\(basePath)/\(roomId)/files"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getOrCreateRoom, .sendMessage:
            return .post
        case .getRooms, .getMessages:
            return .get
        case .uploadFiles:
            return .post
        }
    }

    var headers: [String: String]? {
        var headers: [String: String] = [
            "SesacKey": NetworkConfig.sesacKey,
            "ProductId": NetworkConfig.productId
        ]

        switch self {
        case .getOrCreateRoom, .sendMessage:
            headers["Content-Type"] = "application/json"
        case .getRooms, .getMessages:
            break
        case .uploadFiles:
            // 멀티파트는 Content-Type을 여기서 고정하지 않고,
            // multipartData()에서 생성된 boundary로 호출부에서 설정합니다.
            break
        }

        if let accessToken = TokenManager.shared.accessToken {
            headers["Authorization"] = accessToken
        }

        return headers
    }

    var parameters: [String: Any]? {
        switch self {
        case .getOrCreateRoom(let opponentId):
            return ["opponent_id": opponentId]

        case .sendMessage(_, let content, let files):
            var body: [String: Any] = [:]
            if let content = content { body["content"] = content }
            if let files = files { body["files"] = files }
            return body.isEmpty ? nil : body

        case .getRooms, .getMessages, .uploadFiles:
            return nil
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .getMessages(_, let cursorDate):
            if let cursorDate = cursorDate {
                return [URLQueryItem(name: "cursor_date", value: cursorDate)]
            } else {
                return nil
            }
        default:
            return nil
        }
    }

    var isMultipart: Bool {
        switch self {
        case .uploadFiles:
            return true
        default:
            return false
        }
    }

    func multipartData() -> (data: Data, boundary: String)? {
        guard case .uploadFiles(_, let files) = self else {
            return nil
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()

        for (index, file) in files.enumerated() {
            let (filename, contentType) = getFileMetadata(for: file.type, index: index)

            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(contentType)\r\n\r\n".data(using: .utf8)!)
            body.append(file.data)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        return (body, boundary)
    }

    private func getFileMetadata(for type: FileType, index: Int) -> (filename: String, contentType: String) {
        switch type {
        case .image:
            return ("file\(index)_\(Int(Date().timeIntervalSince1970 * 1000)).jpg", "image/jpeg")
        case .video:
            return ("file\(index)_\(Int(Date().timeIntervalSince1970 * 1000)).mp4", "video/mp4")
        }
    }
}
