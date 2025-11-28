//
//  FullScreenVideoPlayer.swift
//  Moda
//
//  Created by Suji Jang on 11/26/25.
//

import SwiftUI
import AVKit

struct FullScreenVideoPlayer: View {
    let videoURL: URL
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    @State private var dragOffset: CGFloat = 0
    @State private var localVideoURL: URL?
    @State private var isDownloading = true

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
            await downloadAndPlayVideo()
        }
        .onDisappear {
            player?.pause()
            player = nil

            // 임시 파일 삭제
            if let localURL = localVideoURL {
                try? FileManager.default.removeItem(at: localURL)
            }
        }
    }

    private func downloadAndPlayVideo() async {
        do {
            // 인증 헤더를 포함한 URLRequest 생성
            var request = URLRequest(url: videoURL)
            request.setValue(KFHeaders.sesacKey, forHTTPHeaderField: "SesacKey")
            request.setValue(KFHeaders.productId, forHTTPHeaderField: "ProductId")
            request.setValue(KFHeaders.authorization, forHTTPHeaderField: "Authorization")

            // 동영상을 임시 파일로 다운로드
            let (tempURL, _) = try await URLSession.shared.download(for: request)

            // 임시 파일을 안전한 위치로 복사
            let cacheDir = FileManager.default.temporaryDirectory
            let permanentURL = cacheDir.appendingPathComponent(UUID().uuidString + ".mp4")

            // 기존 파일이 있으면 삭제
            if FileManager.default.fileExists(atPath: permanentURL.path) {
                try? FileManager.default.removeItem(at: permanentURL)
            }

            // 파일 복사
            try FileManager.default.copyItem(at: tempURL, to: permanentURL)

            await MainActor.run {
                self.localVideoURL = permanentURL
                self.player = AVPlayer(url: permanentURL)
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
