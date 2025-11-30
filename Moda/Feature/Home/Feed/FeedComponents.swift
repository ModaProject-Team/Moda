//
//  FeedComponents.swift
//  Moda
//
//  Created by Suji Jang on 11/16/25.
//

import SwiftUI
import CoreLocation

// MARK: - Supporting Views
struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    private var iconColor: Color {
        switch icon {
        case "arrow.up.circle.fill":
            return .green1
        case "heart.fill":
            return .pink1
        case "clock.fill":
            return .blue1
        default:
            return .gray1
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)

                Text(title)
                    .Body2()
                    .foregroundColor(.gray1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white.opacity(0.6))
            )
        }
    }
}

struct PostCardView: View {
    let product: PostCard
    let itemWidth: CGFloat
    let currentLocation: CLLocationCoordinate2D?
    let onLikeTapped: () -> Void
    let onTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            imageSection
            profileSection
            statsSection
            infoSection
        }
        .frame(width: itemWidth, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTapped)
    }

    private var profileSection: some View {
        HStack(spacing: 8) {
            if let profileImage = product.creator.profileImage, !profileImage.isEmpty {
                CachedImageView(
                    url: URL(string: "\(NetworkConfig.baseURL)/v1\(profileImage)"),
                    targetSize: CGSize(width: 24, height: 24),
                    contentMode: .fill,
                    placeholder: {
                        AnyView(
                            Circle()
                                .fill(Color.gray3)
                        )
                    }
                )
                .frame(width: 24, height: 24)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray3)
                    .frame(width: 24, height: 24)
            }

            Text(product.creator.nickname)
                .Body1()
                .foregroundColor(.gray1)

            Spacer()

            Text(product.formattedDate)
                .Body2()
                .foregroundColor(.gray2)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            Button(action: onLikeTapped) {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 16))
                        .foregroundColor(product.isLiked ? .pink1 : .gray3)

                    Text("\(product.likeCount)")
                        .Body2()
                        .foregroundColor(.gray1)
                }
            }

            HStack(spacing: 4) {
                Image(systemName: "bubble.right.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.gray3)

                Text("\(product.commentCount)")
                    .Body2()
                    .foregroundColor(.gray1)
            }

            Spacer()
        }
        .padding(.top, 2)
        .padding(.bottom, -2)
    }

    private var imageSection: some View {
        Group {
            if let imageURL = product.imageURL, !imageURL.isEmpty {
                if product.isVideo {
                    VideoPlayerView(
                        url: URL(string: "\(NetworkConfig.baseURL)/v1\(imageURL)")!,
                        itemWidth: itemWidth
                    )
                    .overlay(completedOverlay)
                } else {
                    CachedImageView(
                        url: URL(string: "\(NetworkConfig.baseURL)/v1\(imageURL)"),
                        contentMode: .fit,
                        placeholder: {
                            AnyView(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.gray5)
                                    .frame(width: itemWidth, height: itemWidth)
                                    .shimmer()
                            )
                        }
                    )
                    .cacheOriginalImage()
                    .fade(duration: 0.2)
                    .frame(width: itemWidth)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.clear)
                            .overlay(completedOverlay)
                    )
                }
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.gray5)
                    .frame(width: itemWidth, height: itemWidth)
                    .shimmer()
                    .overlay(completedOverlay)
            }
        }
    }

    @ViewBuilder
    private var completedOverlay: some View {
        if !product.buyers.isEmpty {
            ZStack {
                Color.gray2.opacity(0.7)

                Text("거래완료")
                    .H2()
                    .foregroundColor(.white)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(product.title)
                .Body1()
                .foregroundColor(.gray1)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 4) {
                if let distance = product.formattedDistance(from: currentLocation.map { ($0.latitude, $0.longitude) }) {
                    Text(distance)
                        .Body2()
                        .foregroundColor(.gray2)
                        .lineLimit(1)

                    Text("·")
                        .Body2()
                        .foregroundColor(.gray2)
                }

                if let location = product.formattedLocation {
                    Text(location)
                        .Body2()
                        .foregroundColor(.gray2)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }

            Text(product.formattedPrice)
                .H2()
                .foregroundColor(.gray1)
        }
        .padding(.top, 6)
        .padding(.bottom, 8)
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .Body1()
                .foregroundColor(isSelected ? .white : .gray1)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color.gray1 : Color.gray5)
                .clipShape(Capsule())
        }
    }
}

struct BannerCarouselView: View {
    @State private var currentPage = 0
    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    private let banners: [BannerItem] = [
        BannerItem(
            title: "친구와 함께하는\n안전한 거래",
            subtitle: "친구와 함께 안심하고 거래해보세요",
            iconName: "check",
            backgroundColor: Color.green1,
            accentColor: Color.green1.opacity(0.7),
            textColor: Color(hex: "#2D7A3E")
        ),
        BannerItem(
            title: "내 주변\n물건 찾기",
            subtitle: "가까운 곳의 물건을 편하게 찾아보세요",
            iconName: "location",
            backgroundColor: Color(hex: "#FFB5B5"),
            accentColor: Color(hex: "#FFB5B5").opacity(0.7),
            textColor: Color(hex: "#C93A3A")
        ),
        BannerItem(
            title: "실시간\n채팅 거래",
            subtitle: "채팅으로 빠르게 소통해보세요",
            iconName: "chat",
            backgroundColor: Color.blue1,
            accentColor: Color.blue1.opacity(0.7),
            textColor: Color(hex: "#2E5C9A")
        )
    ]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $currentPage) {
                ForEach(Array(banners.enumerated()), id: \.offset) { index, banner in
                    BannerCardView(banner: banner)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 110)
            .onReceive(timer) { _ in
                withAnimation {
                    currentPage = (currentPage + 1) % banners.count
                }
            }

            HStack(spacing: 2) {
                Text("\(currentPage + 1)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                Text("/")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                Text("\(banners.count)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                Text("전체")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.4))
            )
            .padding(.trailing, 12)
            .padding(.bottom, 20)
        }
    }
}

struct BannerItem {
    let title: String
    let subtitle: String
    let iconName: String
    let backgroundColor: Color
    let accentColor: Color
    let textColor: Color
}

struct BannerCardView: View {
    let banner: BannerItem

    var body: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            banner.backgroundColor.opacity(0.4),
                            banner.backgroundColor.opacity(0.6),
                            banner.backgroundColor.opacity(0.85),
                            banner.backgroundColor
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(banner.title)
                        .font(.custom("Partial Sans KR", size: 20))
                        .foregroundColor(banner.textColor)
                        .lineLimit(2)

                    Text(banner.subtitle)
                        .Body2()
                        .foregroundColor(banner.textColor.opacity(0.8))
                }
                .padding(.leading, 24)

                Spacer()

                Image(banner.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 85, height: 85)
                    .offset(x: banner.iconName == "chat" ? -88 : (banner.iconName == "check" ? -80 : -76))
            }
            .padding(.vertical, 16)
        }
    }
}
