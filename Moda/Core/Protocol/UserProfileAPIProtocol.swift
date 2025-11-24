//
//  UserProfileAPIProtocol.swift
//  Moda
//
//  Created by 금가경 on 11/15/24.
//

import Foundation

/// 사용자 프로필 관련 API 프로토콜
protocol UserProfileAPIProtocol {
    /// 내 프로필 조회
    func getMyProfile() async throws -> MyProfileResponse

    /// 다른 사람 프로필 조회
    func getUserProfile(userId: String) async throws -> OtherProfileResponse

    /// 내 프로필 수정
    func updateMyProfile(
        nick: String?,
        phoneNum: String?,
        birthDay: String?,
        profileImage: Data?,
        info1: String?,
        info2: String?,
        info3: String?,
        info4: String?,
        info5: String?
    ) async throws -> MyProfileResponse
}

// MARK: - Default Parameters
extension UserProfileAPIProtocol {
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
        try await updateMyProfile(
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
    }
}
