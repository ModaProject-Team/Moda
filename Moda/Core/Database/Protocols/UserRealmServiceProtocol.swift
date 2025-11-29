//
//  UserRealmServiceProtocol.swift
//  Moda
//
//  Created by 금가경 on 11/30/25.
//

import Foundation

/// 사용자 프로필 로컬 저장소 프로토콜
protocol UserRealmServiceProtocol {
    /// 내 프로필 정보 저장
    /// - Parameter user: 저장할 사용자 프로필
    func saveMyProfile(_ user: UserObject) async throws

    /// 내 프로필 정보 조회 (일반 struct로 반환)
    /// - Returns: 저장된 내 프로필 데이터, 없으면 nil
    func getMyProfileData() async -> UserProfileData?

    /// 내 프로필 정보 삭제
    func deleteMyProfile() async throws
}
