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

    init(userProfileAPI: UserProfileAPIProtocol = UserProfileAPI.shared) {
        self.userProfileAPI = userProfileAPI
    }

    func send(_ intent: ProfileEditIntent) {
        switch intent {
        case .onAppear:
            loadProfile()

        case .nicknameChanged(let nickname):
            state.nickname = nickname

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
            do {
                let response = try await userProfileAPI.getMyProfile()
                state.nickname = response.nick
                if let profilePath = response.profileImage,
                   let url = URL(string: NetworkConfig.baseURL + "/v1/" + profilePath) {
                    state.profileImageURL = url
                }
            } catch {
                state.errorMessage = "프로필을 불러올 수 없습니다."
                print("프로필 로드 실패: \(error)")
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
                print("이미지 로드 실패: \(error)")
            }
        }
    }

    private func saveProfile() {
        state.isSaving = true
        Task {
            do {
                var imageData: Data? = nil

                if let selectedImage = state.selectedImage {
                    imageData = selectedImage.jpegData(compressionQuality: 0.8)
                }

                let nickToSend = state.nickname.isEmpty ? nil : state.nickname

                _ = try await userProfileAPI.updateMyProfile(
                    nick: nickToSend,
                    profileImage: imageData
                )

                state.showSuccessAlert = true
            } catch {
                state.errorMessage = "프로필 저장에 실패했습니다."
                print("프로필 저장 실패: \(error)")
            }
            state.isSaving = false
        }
    }
}
