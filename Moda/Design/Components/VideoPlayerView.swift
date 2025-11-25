//
//  VideoPlayerView.swift
//  Moda
//
//  Created by 금가경 on 11/25/25.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let url: URL
    let itemWidth: CGFloat

    @StateObject private var playerManager = VideoPlayerManager()

    var body: some View {
        ZStack {
            if let player = playerManager.player {
                VideoPlayer(player: player)
                    .frame(width: itemWidth, height: itemWidth)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .disabled(true)
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.gray5)
                    .frame(width: itemWidth, height: itemWidth)
            }
        }
        .onAppear {
            playerManager.setupPlayer(url: url)
        }
        .onDisappear {
            playerManager.cleanup()
        }
    }
}

final class VideoPlayerManager: ObservableObject {
    @Published var player: AVPlayer?

    private var statusObserver: NSKeyValueObservation?

    func setupPlayer(url: URL) {
        let headers = [
            "SesacKey": NetworkConfig.sesacKey,
            "ProductId": NetworkConfig.productId,
            "Authorization": TokenManager.shared.accessToken ?? ""
        ]

        let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        player?.isMuted = true
        player?.automaticallyWaitsToMinimizeStalling = false

        statusObserver = playerItem.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
            DispatchQueue.main.async {
                if item.status == .readyToPlay {
                    self?.player?.play()
                }
            }
        }

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }
    }

    func cleanup() {
        statusObserver?.invalidate()
        statusObserver = nil
        NotificationCenter.default.removeObserver(self)
        player?.pause()
        player = nil
    }

    deinit {
        cleanup()
    }
}
