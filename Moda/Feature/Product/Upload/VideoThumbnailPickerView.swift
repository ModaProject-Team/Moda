//
//  VideoThumbnailPickerView.swift
//  Moda
//
//  Created by 금가경 on 11/30/24.
//

import SwiftUI
import AVFoundation

struct VideoThumbnailPickerView: View {
    let videoURL: URL
    let initialTime: Double
    let onConfirm: (Double) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var selectedTime: Double
    @State private var thumbnailImage: UIImage?
    @State private var videoDuration: Double = 0
    @State private var isGenerating = false
    @State private var timelineThumbnails: [UIImage] = []
    @State private var isLoadingTimeline = false

    init(videoURL: URL, initialTime: Double = 0, onConfirm: @escaping (Double) -> Void) {
        self.videoURL = videoURL
        self.initialTime = initialTime
        self.onConfirm = onConfirm
        self._selectedTime = State(initialValue: initialTime)
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        thumbnailPreviewSection
                        timelineSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }

                Spacer()
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .task {
            await loadVideoDuration()
            await loadTimelineThumbnails()
            await generateThumbnail(at: selectedTime)
        }
    }

    private var headerSection: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18))
                    .foregroundColor(.gray1)
            }

            Spacer()

            Text("썸네일 선택")
                .H1()
                .foregroundColor(.gray1)

            Spacer()

            Button {
                onConfirm(selectedTime)
                dismiss()
            } label: {
                Text("완료")
                    .H2()
                    .foregroundColor(thumbnailImage == nil ? .gray3 : .blue1)
            }
            .disabled(thumbnailImage == nil)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
    }

    private var thumbnailPreviewSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("미리보기")
                    .H2()
                    .foregroundColor(.gray1)

                Spacer()
            }

            ZStack {
                if let image = thumbnailImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(height: 400)
                        .cornerRadius(16)
                } else {
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .frame(height: 400)
                        .overlay {
                            if isGenerating {
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .tint(.blue1)
                                    Text("썸네일 생성 중...")
                                        .Body2()
                                        .foregroundColor(.gray2)
                                }
                            } else {
                                Image(systemName: "photo")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray3)
                            }
                        }
                }
            }
        }
    }

    private var timelineThumbnailsView: some View {
        Group {
            if isLoadingTimeline {
                Color.gray5
                    .overlay {
                        ProgressView()
                            .tint(.blue1)
                    }
            } else if !timelineThumbnails.isEmpty {
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        ForEach(Array(timelineThumbnails.enumerated()), id: \.offset) { _, thumbnail in
                            Image(uiImage: thumbnail)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width / CGFloat(timelineThumbnails.count))
                                .clipped()
                        }
                    }
                }
            } else {
                Color.gray5
            }
        }
    }

    private var timelineSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("시간 선택")
                    .H2()
                    .foregroundColor(.gray1)

                Spacer()

                Text(formatTime(selectedTime))
                    .Body1()
                    .foregroundColor(.blue1)
            }

            if videoDuration > 0 {
                VStack(spacing: 12) {
                    // 타임라인 + 슬라이더
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // 타임라인 썸네일 백그라운드
                            timelineThumbnailsView
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            // 선택 인디케이터 (세로 직선)
                            let progress = videoDuration > 0 ? selectedTime / videoDuration : 0
                            let xPosition = geometry.size.width * progress

                            Rectangle()
                                .fill(Color.blue1)
                                .frame(width: 3)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 0)
                                .offset(x: xPosition - 1.5)
                                .allowsHitTesting(false)

                            // 투명 드래그 영역
                            Color.clear
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            let newProgress = max(0, min(1, value.location.x / geometry.size.width))
                                            let newTime = newProgress * videoDuration
                                            selectedTime = newTime
                                            Task {
                                                await generateThumbnail(at: newTime)
                                            }
                                        }
                                        .onEnded { value in
                                            let newProgress = max(0, min(1, value.location.x / geometry.size.width))
                                            let newTime = newProgress * videoDuration
                                            Task {
                                                await generateThumbnail(at: newTime)
                                            }
                                        }
                                )
                        }
                    }
                    .frame(height: 60)

                    HStack {
                        Text("0:00")
                            .Body2()
                            .foregroundColor(.gray3)

                        Spacer()

                        Text(formatTime(videoDuration))
                            .Body2()
                            .foregroundColor(.gray3)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.gray5)
                )
            }

            VStack(spacing: 8) {
                Text("슬라이더를 움직여 원하는 장면을 썸네일로 선택하세요")
                    .Body2()
                    .foregroundColor(.gray2)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)
        }
    }

    private func loadVideoDuration() async {
        do {
            let metadata = try await VideoParser.shared.parseMetadata(from: videoURL)
            await MainActor.run {
                self.videoDuration = metadata.duration.seconds
            }
        } catch {
            await MainActor.run {
                self.videoDuration = 0
            }
        }
    }

    private func generateThumbnail(at time: Double) async {
        await MainActor.run {
            self.isGenerating = true
        }

        let cmTime = CMTime(seconds: time, preferredTimescale: 600)

        do {
            let thumbnail = try await VideoParser.shared.generateThumbnail(from: videoURL, at: cmTime)
            await MainActor.run {
                self.thumbnailImage = thumbnail
                self.isGenerating = false
            }
        } catch {
            await MainActor.run {
                self.thumbnailImage = nil
                self.isGenerating = false
            }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    private func loadTimelineThumbnails() async {
        await MainActor.run {
            self.isLoadingTimeline = true
        }

        do {
            let thumbnails = try await VideoParser.shared.generateThumbnails(
                from: videoURL,
                count: 12,
                size: CGSize(width: 100, height: 100)
            )
            await MainActor.run {
                self.timelineThumbnails = thumbnails
                self.isLoadingTimeline = false
            }
        } catch {
            await MainActor.run {
                self.timelineThumbnails = []
                self.isLoadingTimeline = false
            }
        }
    }
}
