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
        Group {
            if let player = playerManager.player, let aspectRatio = playerManager.videoAspectRatio {
                VideoPlayerLayer(player: player)
                    .aspectRatio(aspectRatio, contentMode: .fit)
                    .frame(width: itemWidth)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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

struct VideoPlayerLayer: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> VideoPlayerUIView {
        VideoPlayerUIView(player: player)
    }

    func updateUIView(_ uiView: VideoPlayerUIView, context: Context) {
        uiView.player = player
    }
}

final class VideoPlayerUIView: UIView {
    var player: AVPlayer? {
        didSet {
            playerLayer.player = player
        }
    }

    private var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }

    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    init(player: AVPlayer) {
        self.player = player
        super.init(frame: .zero)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class VideoPlayerManager: ObservableObject {
    @Published var player: AVPlayer?
    @Published var videoAspectRatio: CGFloat?

    private var statusObserver: NSKeyValueObservation?
    private let cacheManager = VideoCacheManager.shared

    func setupPlayer(url: URL) {
        Task {
            do {
                let localURL = try await getCachedOrDownload(url: url)
                await setupPlayerWithURL(localURL)
            } catch {
                print("Failed to load video: \(error.localizedDescription)")
                await MainActor.run {
                    self.videoAspectRatio = 1.0
                }
            }
        }
    }

    private func getCachedOrDownload(url: URL) async throws -> URL {
        if let cachedURL = cacheManager.getCachedVideo(for: url) {
            return cachedURL
        }

        return try await cacheManager.cacheVideo(from: url)
    }

    @MainActor
    private func setupPlayerWithURL(_ url: URL) async {
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        player?.isMuted = true
        player?.automaticallyWaitsToMinimizeStalling = false

        Task {
            do {
                let tracks = try await asset.loadTracks(withMediaType: .video)
                if let videoTrack = tracks.first {
                    let size = try await videoTrack.load(.naturalSize)
                    let transform = try await videoTrack.load(.preferredTransform)

                    let videoWidth: CGFloat
                    let videoHeight: CGFloat

                    if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
                        videoWidth = size.height
                        videoHeight = size.width
                    } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
                        videoWidth = size.height
                        videoHeight = size.width
                    } else {
                        videoWidth = size.width
                        videoHeight = size.height
                    }

                    await MainActor.run {
                        self.videoAspectRatio = videoWidth / videoHeight
                    }
                }
            } catch {
                await MainActor.run {
                    self.videoAspectRatio = 1.0
                }
            }
        }

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
