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
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getOrCreateRoom, .sendMessage:
            return .post
        case .getRooms, .getMessages:
            return .get
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

        case .getRooms, .getMessages:
            return nil
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .getMessages(_, let cursorDate):
            // 비어있는 문자열을 보내면 전체 조회가 가능하다고 명세에 있으므로,
            // nil이면 쿼리 자체를 생략, 빈 문자열을 보내고 싶다면 호출부에서 "" 전달
            if let cursorDate = cursorDate {
                return [URLQueryItem(name: "cursor_date", value: cursorDate)]
            } else {
                return nil
            }
        default:
            return nil
        }
    }
}
