//
//  UserProfileRouter.swift
//  Moda
//
//  Created by 금가경 on 11/15/24.
//

import Foundation

/// 사용자 프로필 관련 API 엔드포인트
enum UserProfileRouter {
    /// 내 프로필 조회
    case getMyProfile

    /// 다른 사람 프로필 조회
    case getUserProfile(userId: String)

    /// 내 프로필 수정
    case updateMyProfile(
        nick: String?,
        phoneNum: String?,
        birthDay: String?,
        profileImage: Data?,
        info1: String?,
        info2: String?,
        info3: String?,
        info4: String?,
        info5: String?
    )
}

// MARK: - Endpoint 구현
extension UserProfileRouter: Endpoint {

    var baseURL: String {
        return NetworkConfig.baseURL
    }

    var path: String {
        let basePath = "/v1/users"
        let subPath: String

        switch self {
        case .getMyProfile, .updateMyProfile:
            subPath = "/me/profile"
        case .getUserProfile(let userId):
            subPath = "/\(userId)/profile"
        }

        return basePath + subPath
    }

    var method: HTTPMethod {
        switch self {
        case .getMyProfile, .getUserProfile:
            return .get
        case .updateMyProfile:
            return .put
        }
    }

    var headers: [String: String]? {
        var headers: [String: String] = [
            "SesacKey": NetworkConfig.sesacKey,
            "ProductId": NetworkConfig.productId
        ]

        // multipart가 아닌 경우만 Content-Type 지정
        switch self {
        case .updateMyProfile:
            // multipart는 boundary를 포함한 Content-Type이 필요하므로 여기서 설정 안 함
            break
        default:
            headers["Content-Type"] = "application/json"
        }

        if let accessToken = TokenManager.shared.accessToken {
            headers["Authorization"] = accessToken
        }

        return headers
    }

    var parameters: [String: Any]? {
        return nil
    }

    var queryItems: [URLQueryItem]? {
        return nil
    }

    /// Multipart 데이터 여부
    var isMultipart: Bool {
        switch self {
        case .updateMyProfile:
            return true
        default:
            return false
        }
    }

    /// Multipart 데이터 생성
    func multipartData() -> (data: Data, boundary: String)? {
        guard case .updateMyProfile(
            let nick,
            let phoneNum,
            let birthDay,
            let profileImage,
            let info1,
            let info2,
            let info3,
            let info4,
            let info5
        ) = self else {
            return nil
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()

        // 텍스트 필드 추가
        func appendTextField(name: String, value: String?) {
            guard let value = value else { return }
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        appendTextField(name: "nick", value: nick)
        appendTextField(name: "phoneNum", value: phoneNum)
        appendTextField(name: "birthDay", value: birthDay)
        appendTextField(name: "info1", value: info1)
        appendTextField(name: "info2", value: info2)
        appendTextField(name: "info3", value: info3)
        appendTextField(name: "info4", value: info4)
        appendTextField(name: "info5", value: info5)

        // 이미지 파일 추가
        if let imageData = profileImage {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"profile\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        return (body, boundary)
    }
}
