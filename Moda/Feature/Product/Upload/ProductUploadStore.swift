//
//  ProductUploadStore.swift
//  Moda
//
//  Created by Suji Jang on 11/15/24.
//

import SwiftUI
import PhotosUI

final class ProductUploadStore: ObservableObject {
    
    @Published private(set) var state = ProductUploadState()
    private let postAPI: PostAPIProtocol

    init(postAPI: PostAPIProtocol = PostAPI.shared) {
        self.postAPI = postAPI
    }

    func send(_ intent: ProductUploadIntent) {
        switch intent {
        case .titleChanged(let title):
            state.title = title
        case .descriptionChanged(let description):
            state.description = description
        case .priceChanged(let price):
            state.price = price
        case .sellingTypeChanged(let isSelling):
            state.isSelling = isSelling
        case .priceNegotiableToggled:
            state.isPriceNegotiable.toggle()
        case .locationTapped:
            state.showLocationSelection = true
        case .locationSelected(let name, let latitude, let longitude):
            state.locationName = name
            state.latitude = latitude
            state.longitude = longitude
            state.showLocationSelection = false
        case .dismissLocationSelection:
            state.showLocationSelection = false
        case .imagesSelected(let items):
            Task {
                await loadImages(from: items)
            }
        case .imageRemoved(let index):
            state.selectedImages.remove(at: index)
        case .submitButtonTapped:
            Task {
                await uploadPost()
            }
        }
    }

    @MainActor
    private func loadImages(from items: [PhotosPickerItem]) async {
        var images: [UIImage] = []

        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                images.append(image)
            }
        }

        state.selectedImages.append(contentsOf: images)

        if state.selectedImages.count > 5 {
            state.selectedImages = Array(state.selectedImages.prefix(5))
        }
    }

    @MainActor
    private func uploadPost() async {
        // 유효성 검사
        guard !state.title.isEmpty else {
            state.uploadError = "제목을 입력해주세요"
            return
        }

        guard state.isSelling == false || !state.price.isEmpty else {
            state.uploadError = "가격을 입력해주세요"
            return
        }

        // UI에서 ProgressView, 버튼 비활성 등 처리
        state.isUploading = true
        state.uploadError = nil

        do {
            // 1. 이미지가 있으면 먼저 파일 업로드
            var uploadedFileURLs: [String] = []

            if !state.selectedImages.isEmpty {
                let imageDataArray = state.selectedImages.compactMap { $0.jpegData(compressionQuality: 0.8) }
                let uploadResponse = try await postAPI.uploadFiles(files: imageDataArray)
                uploadedFileURLs = uploadResponse.files
            }

            // 2. 게시글 생성
            let priceValue = state.isSelling ? Int(state.price) : nil
            let response = try await postAPI.createPost(
                category: "sell", // 판매 카테고리
                title: state.title,
                price: priceValue,
                content: state.description.isEmpty ? nil : state.description,
                value1: state.locationName.isEmpty ? nil : state.locationName,
                content2: nil,
                content3: nil,
                content4: nil,
                content5: nil,
                files: uploadedFileURLs,
                longitude: state.longitude,
                latitude: state.latitude
            )

            state.isUploading = false

            //TODO: 성공 처리 (게시글 상세 화면으로 이동하거나 뒤로가기)
            print("게시글 등록 성공: \(response.postId)")

        } catch {
            state.isUploading = false
            state.uploadError = error.localizedDescription
            print("게시글 등록 실패: \(error)")
        }
    }
}
