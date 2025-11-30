//
//  CachedImageView.swift
//  Moda
//
//  Created by 금가경 on 11/30/24.
//

import SwiftUI

/// 캐싱된 이미지를 표시하는 뷰
///
/// Downsampling을 지원하여 메모리 효율적인 이미지 로딩을 제공합니다.
struct CachedImageView: View {
    let url: URL?
    let targetSize: CGSize?
    let contentMode: SwiftUI.ContentMode
    let placeholder: (() -> AnyView)?
    let fade: Bool

    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var downloadTask: Task<Void, Never>?

    private let cacheManager = ImageCacheManager.shared

    init(
        url: URL?,
        targetSize: CGSize? = nil,
        contentMode: SwiftUI.ContentMode = .fill,
        fade: Bool = true,
        placeholder: (() -> AnyView)? = nil
    ) {
        self.url = url
        self.targetSize = targetSize
        self.contentMode = contentMode
        self.fade = fade
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = image {
                if fade {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                } else {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                }
            } else if isLoading {
                if let placeholder = placeholder {
                    placeholder()
                } else {
                    defaultPlaceholder
                }
            } else {
                if let placeholder = placeholder {
                    placeholder()
                } else {
                    errorPlaceholder
                }
            }
        }
        .onAppear {
            downloadTask = Task {
                await loadImage()
            }
        }
        .onDisappear {
            downloadTask?.cancel()
            if let url = url {
                Task {
                    await cacheManager.cancelImageDownload(for: url)
                }
            }
        }
    }

    private var defaultPlaceholder: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay {
                ProgressView()
                    .tint(.gray)
            }
    }

    private var errorPlaceholder: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay {
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            }
    }

    private func loadImage() async {
        guard let url = url else {
            isLoading = false
            return
        }

        // 동기적 캐시 확인
        if let cachedImage = cacheManager.getCachedImage(for: url, targetSize: targetSize) {
            await MainActor.run {
                self.image = cachedImage
                self.isLoading = false
            }
            return
        }

        // 비동기 다운로드 및 캐싱
        do {
            let downloadedImage = try await cacheManager.cacheImage(from: url, targetSize: targetSize)
            await MainActor.run {
                self.image = downloadedImage
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

extension CachedImageView {
    /// 원본 크기로 이미지 캐싱
    func cacheOriginalImage() -> Self {
        self
    }

    /// Downsampling할 타겟 크기 지정
    func downsample(to size: CGSize) -> CachedImageView {
        CachedImageView(
            url: url,
            targetSize: size,
            contentMode: contentMode,
            fade: fade,
            placeholder: placeholder
        )
    }

    /// Fade 애니메이션 설정
    func fade(duration: Double) -> CachedImageView {
        CachedImageView(
            url: url,
            targetSize: targetSize,
            contentMode: contentMode,
            fade: duration > 0,
            placeholder: placeholder
        )
    }

    /// Placeholder 설정
    func placeholder<Content: View>(@ViewBuilder _ content: @escaping () -> Content) -> CachedImageView {
        CachedImageView(
            url: url,
            targetSize: targetSize,
            contentMode: contentMode,
            fade: fade,
            placeholder: { AnyView(content()) }
        )
    }

    /// 다운로드 취소 on disappear 설정 (호환성 유지)
    func cancelOnDisappear(_ cancel: Bool) -> Self {
        self
    }
}
