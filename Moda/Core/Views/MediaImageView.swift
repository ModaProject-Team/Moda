//
//  MediaImageView.swift
//  Moda
//
//  Created by Suji Jang on 11/26/25.
//

import SwiftUI
import Kingfisher
import AVFoundation

/// 이미지 또는 동영상 URL을 받아서 적절한 썸네일을 표시하는 뷰
struct MediaImageView: View {
    let mediaURL: String
    let placeholder: (() -> AnyView)?
    let contentMode: SwiftUI.ContentMode

    init(
        mediaURL: String,
        contentMode: SwiftUI.ContentMode = .fill,
        placeholder: (() -> AnyView)? = nil
    ) {
        self.mediaURL = mediaURL
        self.contentMode = contentMode
        self.placeholder = placeholder
    }

    var body: some View {
        let fullURL = "\(NetworkConfig.baseURL)/v1\(mediaURL)"
        let isVideo = mediaURL.isVideoFile

        if isVideo {
            MediaVideoThumbnailView(videoURL: fullURL, contentMode: contentMode)
        } else {
            KFImage(URL(string: fullURL))
                .requestModifier(KFHeaders.modifier)
                .placeholder {
                    if let placeholder = placeholder {
                        placeholder()
                    } else {
                        defaultPlaceholder
                    }
                }
                .cacheOriginalImage()
                .fade(duration: 0.2)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        }
    }

    private var defaultPlaceholder: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay {
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            }
    }
}

/// 동영상 URL에서 썸네일을 생성하여 표시하는 뷰
struct MediaVideoThumbnailView: View {
    let videoURL: String
    let contentMode: SwiftUI.ContentMode

    @State private var thumbnail: UIImage?
    @State private var isLoading = true

    private let cacheManager = VideoCacheManager.shared

    var body: some View {
        Group {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if isLoading {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        ProgressView()
                            .tint(.gray)
                    }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        Image(systemName: "video.slash")
                            .foregroundColor(.gray)
                    }
            }
        }
        .task {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        guard let url = URL(string: videoURL) else {
            isLoading = false
            return
        }

        do {
            let image = try await cacheManager.cacheThumbnail(from: url)
            await MainActor.run {
                self.thumbnail = image
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}
