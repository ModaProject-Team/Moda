//
//  VideoPlayerView.swift
//  Moda
//
//  Created by 금가경 on 11/25/25.
//

import Yolk
import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let url: URL
    let itemWidth: CGFloat
    let customScheme: String

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
                    .shimmer()
            }
        }
        .task(id: url) {
            await playerManager.setupPlayer(url: url, customScheme: customScheme)
        }
        .onDisappear {
            playerManager.pause()
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
    private var resourceLoader: AuthenticatedResourceLoader?
    private let cacheService = CacheService.video
    private var currentURL: URL?

    func setupPlayer(url: URL, customScheme: String) async {
        // 이미 같은 URL로 설정되어 있으면 재생만 재개
        if currentURL == url, player != nil {
            await MainActor.run {
                player?.play()
            }
            return
        }

        currentURL = url

        // 캐시된 동영상이 있으면 로컬 파일 재생
        if let cachedURL = await cacheService.getCachedVideo(for: url) {
            await setupPlayerWithURL(cachedURL)
            return
        }

        // 캐시가 없으면 206 스트리밍 + 백그라운드 다운로드
        await setupStreamingPlayer(url: url, customScheme: customScheme)

        // 백그라운드에서 전체 동영상 다운로드 (캐싱용)
        Task(priority: .low) {
            do {
                _ = try await cacheService.cacheVideo(from: url)
            } catch {
            }
        }
    }

    @MainActor
    private func setupStreamingPlayer(url: URL, customScheme: String) async {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return
        }
        components.scheme = customScheme

        guard let streamingURL = components.url else {
            return
        }

        // Moda 프로젝트 헤더 추가를 위한 modifier
        let modifier = AnyModifier { request in
            var r = request
            r.setValue(NetworkConfig.sesacKey, forHTTPHeaderField: "SesacKey")
            r.setValue(NetworkConfig.productId, forHTTPHeaderField: "ProductId")
            r.setValue(TokenManager.shared.accessToken ?? "", forHTTPHeaderField: "Authorization")
            return r
        }

        let loader = AuthenticatedResourceLoader(customScheme: customScheme, modifier: modifier)
        self.resourceLoader = loader

        let asset = AVURLAsset(url: streamingURL)
        asset.resourceLoader.setDelegate(loader, queue: DispatchQueue(label: "com.moda.resourceloader"))

        let playerItem = AVPlayerItem(asset: asset)

        // 기본 종횡비로 플레이어 먼저 설정 (shimmer 즉시 제거)
        self.videoAspectRatio = 1.0
        self.player = AVPlayer(playerItem: playerItem)
        self.player?.isMuted = true
        self.player?.automaticallyWaitsToMinimizeStalling = false

        self.statusObserver = playerItem.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
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

        // 백그라운드에서 실제 종횡비 로드 후 업데이트
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
                // 실제 종횡비 로드 실패 시 기본값(1.0) 유지
            }
        }
    }

    @MainActor
    private func setupPlayerWithURL(_ url: URL) async {
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)

        // 기본 종횡비로 플레이어 먼저 설정 (shimmer 즉시 제거)
        self.videoAspectRatio = 1.0
        self.player = AVPlayer(playerItem: playerItem)
        self.player?.isMuted = true
        self.player?.automaticallyWaitsToMinimizeStalling = false

        self.statusObserver = playerItem.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
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

        // 백그라운드에서 실제 종횡비 로드 후 업데이트
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
                // 실제 종횡비 로드 실패 시 기본값(1.0) 유지
            }
        }
    }

    func pause() {
        player?.pause()
    }

    func cleanup() {
        statusObserver?.invalidate()
        statusObserver = nil
        NotificationCenter.default.removeObserver(self)
        player?.pause()
        player = nil
        resourceLoader?.cancelAllRequests()
        resourceLoader = nil
        currentURL = nil
    }

    deinit {
        cleanup()
    }
}
