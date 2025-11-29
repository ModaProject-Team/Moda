//
//  ProfileEditStore.swift
//  Moda
//
//  Created by Suji Jang on 11/24/24.
//

import SwiftUI
import PhotosUI

@MainActor
@Observable
final class ProfileEditStore {
    var state = ProfileEditState()

    private let userProfileAPI: UserProfileAPIProtocol
    private let userRealmService: UserRealmServiceProtocol

    init(
        userProfileAPI: UserProfileAPIProtocol = UserProfileAPI.shared,
        userRealmService: UserRealmServiceProtocol = UserRealmService.shared
    ) {
        self.userProfileAPI = userProfileAPI
        self.userRealmService = userRealmService
    }

    func send(_ intent: ProfileEditIntent) {
        switch intent {
        case .onAppear:
            loadProfile()

        case .nicknameChanged(let nickname):
            state.nickname = nickname

        case .statusMessageChanged(let statusMessage):
            state.statusMessage = statusMessage

        case .imageSelected(let item):
            state.selectedItem = item
            loadSelectedImage(item)

        case .saveTapped:
            saveProfile()

        case .dismissError:
            state.errorMessage = nil
        }
    }

    private func loadProfile() {
        state.isLoading = true
        Task {
            // 로컬 프로필 먼저 로드
            if let localProfile = await userRealmService.getMyProfileData() {
                state.nickname = localProfile.nick
                state.statusMessage = localProfile.info1 ?? ""
                if let profilePath = localProfile.profileImage,
                   let url = URL(string: NetworkConfig.baseURL + "/v1/" + profilePath) {
                    state.profileImageURL = url
                }
            }

            // 서버와 동기화 시도
            do {
                let response = try await userProfileAPI.getMyProfile()
                state.nickname = response.nick
                state.statusMessage = response.info1 ?? ""
                if let profilePath = response.profileImage,
                   let url = URL(string: NetworkConfig.baseURL + "/v1/" + profilePath) {
                    state.profileImageURL = url
                }

                // 서버 프로필을 로컬에 저장
                let userObject = UserObject.from(response: response)
                try? await userRealmService.saveMyProfile(userObject)
            } catch {
                // 네트워크 오류 시 로컬 데이터로 유지
                state.errorMessage = "프로필을 불러올 수 없습니다."
            }
            state.isLoading = false
        }
    }

    private func loadSelectedImage(_ item: PhotosPickerItem?) {
        guard let item = item else { return }

        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    state.selectedImage = uiImage
                }
            } catch {
                state.errorMessage = "이미지를 불러올 수 없습니다."
            }
        }
    }

    private func saveProfile() {
        state.isSaving = true
        Task {
            do {
                var imageData: Data? = nil

                if let selectedImage = state.selectedImage {
                    // ImageCompressor를 사용하여 이미지 압축
                    if let compressed = ImageCompressor.shared.compress(
                        image: selectedImage,
                        maxSizeInKB: 100
                    ) {
                        imageData = compressed.data
                    }
                }

                // 닉네임이 비어있거나 공백만 있으면 nil로 전송
                let nickToSend = state.nickname.trimmingCharacters(in: .whitespaces).isEmpty ? nil : state.nickname.trimmingCharacters(in: .whitespaces)
                let statusToSend = state.statusMessage.trimmingCharacters(in: .whitespaces).isEmpty ? nil : state.statusMessage

                let updatedProfile = try await userProfileAPI.updateMyProfile(
                    nick: nickToSend,
                    profileImage: imageData,
                    info1: statusToSend
                )

                // 로컬 DB에 즉시 반영
                let userObject = UserObject.from(response: updatedProfile)
                try? await userRealmService.saveMyProfile(userObject)

                state.shouldDismiss = true
            } catch {
                state.errorMessage = "프로필 저장에 실패했습니다."
            }
            state.isSaving = false
        }
    }
}
