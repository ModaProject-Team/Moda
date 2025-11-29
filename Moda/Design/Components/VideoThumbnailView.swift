//
//  VideoThumbnailView.swift
//  Moda
//
//  Created by 금가경 on 11/25/25.
//

import SwiftUI
import AVFoundation

struct VideoThumbnailView: View {
    let url: URL
    let itemWidth: CGFloat

    @State private var thumbnailImage: UIImage?
    @State private var isLoading = true

    private let cacheManager = VideoCacheManager.shared

    var body: some View {
        ZStack {
            if let thumbnail = thumbnailImage {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: itemWidth, height: itemWidth)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.gray5)
                    .frame(width: itemWidth, height: itemWidth)
            }

            if isLoading {
                ProgressView()
                    .tint(.gray2)
            }

            Image(systemName: "play.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.3), radius: 4)
        }
        .onAppear {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        Task {
            do {
                let thumbnail = try await cacheManager.cacheThumbnail(from: url)
                await MainActor.run {
                    self.thumbnailImage = thumbnail
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}
