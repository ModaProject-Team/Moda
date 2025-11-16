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
