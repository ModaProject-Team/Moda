//
//  ProductUploadStore.swift
//  Moda
//
//  Created by Suji Jang on 11/15/24.
//

import SwiftUI
import PhotosUI
import AVFoundation
import UniformTypeIdentifiers

struct Movie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = URL.documentsDirectory.appending(path: "movie-\(UUID().uuidString).mp4")
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self(url: copy)
        }
    }
}

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
                await loadMedia(from: items)
            }
        case .imageRemoved(let index):
            state.selectedMedia.remove(at: index)
        case .submitButtonTapped:
            Task {
                await uploadPost()
            }
        case .dismissFileSizeAlert:
            state.showFileSizeAlert = false
        }
    }

    @MainActor
    private func loadMedia(from items: [PhotosPickerItem]) async {
        var mediaItems: [MediaItem] = []

        for item in items {
            if let movie = try? await item.loadTransferable(type: Movie.self) {
                let fileSize = getFileSize(url: movie.url)
                let maxSize: Int64 = 10 * 1024 * 1024

                if fileSize > maxSize {
                    state.showFileSizeAlert = true
                    continue
                }

                if let thumbnail = await generateThumbnail(from: movie.url) {
                    mediaItems.append(.video(url: movie.url, thumbnail: thumbnail))
                }
            } else if let data = try? await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) {
                mediaItems.append(.image(image))
            }
        }

        state.selectedMedia.append(contentsOf: mediaItems)

        if state.selectedMedia.count > 5 {
            state.selectedMedia = Array(state.selectedMedia.prefix(5))
        }
    }

    private func getFileSize(url: URL) -> Int64 {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int64 else {
            return 0
        }
        return fileSize
    }

    private func generateThumbnail(from url: URL) async -> UIImage? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        do {
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("썸네일 생성 실패: \(error)")
            return nil
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
            // 1. 미디어 파일 업로드
            var uploadedFileURLs: [String] = []

            if !state.selectedMedia.isEmpty {
                var fileDataArray: [FileData] = []

                for media in state.selectedMedia {
                    switch media {
                    case .image(let image):
                        if let imageData = image.jpegData(compressionQuality: 0.8) {
                            fileDataArray.append(FileData(data: imageData, type: .image))
                        }
                    case .video(let url, _):
                        if let videoData = try? Data(contentsOf: url) {
                            fileDataArray.append(FileData(data: videoData, type: .video))
                        }
                    }
                }

                let uploadResponse = try await postAPI.uploadFiles(files: fileDataArray)
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
            state.uploadedPostId = response.postId

        } catch {
            state.isUploading = false
            state.uploadError = error.localizedDescription
            print("게시글 등록 실패: \(error)")
        }
    }
}
