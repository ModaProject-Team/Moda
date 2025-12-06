//
//  FullScreenVideoPlayer.swift
//  Moda
//
//  Created by Suji Jang on 11/26/25.
//

import Yolk
import SwiftUI
import AVKit

struct FullScreenVideoPlayer: View {
    let videoURL: URL
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    @State private var dragOffset: CGFloat = 0
    @State private var isDownloading = true

    private let cacheService = CacheService.video

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)

                    if isDownloading {
                        Text("동영상 로딩 중...")
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                }
            }

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 44, height: 44)

                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 16)
                }
                .padding(.top)
                Spacer()
            }
        }
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 100 {
                        dismiss()
                    } else {
                        withAnimation(.spring()) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .task {
            await loadAndPlayVideo()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    private func loadAndPlayVideo() async {
        do {
            let localURL = try await cacheService.cacheVideo(from: videoURL)
            await MainActor.run {
                self.player = AVPlayer(url: localURL)
                self.player?.play()
                self.isDownloading = false
            }
        } catch {
            await MainActor.run {
                self.isDownloading = false
            }
        }
    }
}
