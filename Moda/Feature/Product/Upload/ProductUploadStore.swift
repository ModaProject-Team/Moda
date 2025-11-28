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
    private let editMode: Bool

    init(editMode: Bool = false, postId: String? = nil, postAPI: PostAPIProtocol = PostAPI.shared) {
        self.editMode = editMode
        self.postAPI = postAPI

        // 수정 모드일 때 서버에서 데이터 로드
        if editMode, let postId = postId {
            state.originalPostId = postId
            Task {
                await loadPostData(postId: postId)
            }
        }
    }

    @MainActor
    private func loadPostData(postId: String) async {
        do {
            let post = try await postAPI.getPost(postId: postId)

            state.title = post.title
            state.description = post.content ?? ""
            state.price = post.price != nil ? "\(post.price!)" : ""
            state.isSelling = post.price != nil && post.price! > 0
            state.locationName = post.value1 ?? ""
            state.latitude = post.geolocation?.latitude
            state.longitude = post.geolocation?.longitude
            state.originalFiles = post.files

            // 기존 파일들을 MediaItem으로 변환하여 UI에 표시
            await loadExistingMedia(files: post.files)
        } catch {
            print("게시글 로드 실패: \(error)")
            state.uploadError = "게시글을 불러올 수 없습니다."
        }
    }

    @MainActor
    private func loadExistingMedia(files: [String]) async {
        var mediaItems: [MediaItem] = []

        for fileURL in files {
            let fullURL = "\(NetworkConfig.baseURL)/v1\(fileURL)"
            
            if fileURL.isImageFile {
                if let url = URL(string: fullURL) {
                    var request = URLRequest(url: url)
                    request.setValue(KFHeaders.sesacKey, forHTTPHeaderField: "SesacKey")
                    request.setValue(KFHeaders.productId, forHTTPHeaderField: "ProductId")
                    request.setValue(KFHeaders.authorization, forHTTPHeaderField: "Authorization")
                    
                    do {
                        let (data, _) = try await URLSession.shared.data(for: request)
                        
                        if let image = UIImage(data: data) {
                            mediaItems.append(.image(image, serverURL: fileURL))
                        }
                    } catch {
                        print("다운로드 실패: \(error)")
                    }
                }
            } else if fileURL.isVideoFile {
                if let url = URL(string: fullURL) {
                    do {
                        let (tempURL, _) = try await downloadFileWithAuth(from: url)

                        // 임시 파일을 Documents 디렉토리에 .mp4 확장자로 복사
                        let permanentURL = URL.documentsDirectory.appending(path: "downloaded-\(UUID().uuidString).mp4")
                        try FileManager.default.copyItem(at: tempURL, to: permanentURL)

                        // 임시 파일 삭제
                        try? FileManager.default.removeItem(at: tempURL)

                        if let thumbnail = await generateThumbnail(from: permanentURL) {
                            mediaItems.append(.video(url: permanentURL, thumbnail: thumbnail, serverURL: fileURL))
                        }
                    } catch {
                        print("동영상 다운로드 실패: \(error)")
                    }
                }
            }
        }
        state.selectedMedia = mediaItems
    }

    private func downloadFileWithAuth(from url: URL) async throws -> (URL, URLResponse) {
        var request = URLRequest(url: url)
        request.setValue(KFHeaders.sesacKey, forHTTPHeaderField: "SesacKey")
        request.setValue(KFHeaders.productId, forHTTPHeaderField: "ProductId")
        request.setValue(KFHeaders.authorization, forHTTPHeaderField: "Authorization")

        return try await URLSession.shared.download(for: request)
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
            let removedMedia = state.selectedMedia[index]

            // 서버 파일인 경우 originalFiles에서도 제거
            if let serverURL = removedMedia.serverURL {
                state.originalFiles.removeAll { $0 == serverURL }
            }

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
                let compressedURL = try? await VideoCompressor.shared.compress(url: movie.url)
                let videoURL = compressedURL ?? movie.url

                if let thumbnail = await generateThumbnail(from: videoURL) {
                    mediaItems.append(.video(url: videoURL, thumbnail: thumbnail))
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
            var uploadedFileURLs: [String] = state.originalFiles // 기존 파일 유지 (삭제된 파일은 이미 제거됨)

            // 새로 추가한 미디어만 업로드 (serverURL이 nil인 것)
            let newMedia = state.selectedMedia.filter { $0.serverURL == nil }

            if !newMedia.isEmpty {
                var fileDataArray: [FileData] = []

                for media in newMedia {
                    switch media {
                    case .image(let image, _):
                        if let imageData = image.jpegData(compressionQuality: 0.8) {
                            fileDataArray.append(FileData(data: imageData, type: .image))
                        }
                    case .video(let url, _, _):
                        if let videoData = try? Data(contentsOf: url) {
                            fileDataArray.append(FileData(data: videoData, type: .video))
                        }
                    }
                }

                if !fileDataArray.isEmpty {
                    let uploadResponse = try await postAPI.uploadFiles(files: fileDataArray)
                    uploadedFileURLs.append(contentsOf: uploadResponse.files)
                }
            }

            let priceValue = state.isSelling ? Int(state.price) : nil

            // 2. 게시글 생성 또는 수정
            if editMode, let postId = state.originalPostId {
                // 수정 모드
                _ = try await postAPI.updatePost(
                    postId: postId,
                    category: "sell",
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
                state.uploadedPostId = postId

                // 게시글 수정 완료 알림 전송
                NotificationCenter.default.post(name: .postUpdated, object: nil)
            } else {
                // 생성 모드
                let response = try await postAPI.createPost(
                    category: "sell",
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

                // 게시글 작성 완료 알림 전송
                NotificationCenter.default.post(name: .postUpdated, object: nil)
            }

        } catch {
            state.isUploading = false
            state.uploadError = error.localizedDescription
            print("게시글 \(editMode ? "수정" : "등록") 실패: \(error)")
        }
    }
}
