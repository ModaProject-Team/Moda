//
//  UserProfileAPI.swift
//  Moda
//
//  Created by 금가경 on 11/15/24.
//

import Foundation

/// 사용자 프로필 관련 API 통신을 처리하는 클래스
///
/// 프로필 조회 및 수정 API 호출을 제공합니다.
final class UserProfileAPI: UserProfileAPIProtocol {
    static let shared = UserProfileAPI()

    private let networkService: NetworkServiceProtocol

    private init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
    }

    func getMyProfile() async throws -> MyProfileResponse {
        let endpoint = UserProfileRouter.getMyProfile
        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: MyProfileResponse.self
        )

        return response
    }

    func getUserProfile(userId: String) async throws -> OtherProfileResponse {
        let endpoint = UserProfileRouter.getUserProfile(userId: userId)
        let response = try await networkService.request(
            endpoint: endpoint,
            responseType: OtherProfileResponse.self
        )

        return response
    }

    func updateMyProfile(
        nick: String? = nil,
        phoneNum: String? = nil,
        birthDay: String? = nil,
        profileImage: Data? = nil,
        info1: String? = nil,
        info2: String? = nil,
        info3: String? = nil,
        info4: String? = nil,
        info5: String? = nil
    ) async throws -> MyProfileResponse {
        let endpoint = UserProfileRouter.updateMyProfile(
            nick: nick,
            phoneNum: phoneNum,
            birthDay: birthDay,
            profileImage: profileImage,
            info1: info1,
            info2: info2,
            info3: info3,
            info4: info4,
            info5: info5
        )

        // Multipart 요청 처리
        guard let multipartData = endpoint.multipartData() else {
            throw NetworkError.invalidURL
        }

        var request = try endpoint.asURLRequest()
        request.setValue("multipart/form-data; boundary=\(multipartData.boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = multipartData.data

        let (data, urlResponse) = try await URLSession.shared.data(for: request)

        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(message: "상태 코드: \(httpResponse.statusCode)")
        }

        let response = try JSONDecoder().decode(MyProfileResponse.self, from: data)
        return response
    }
}
