//
//  FeedComponents.swift
//  Moda
//
//  Created by Suji Jang on 11/16/25.
//

import SwiftUI
import Kingfisher
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
                KFImage(URL(string: "\(NetworkConfig.baseURL)/v1\(profileImage)"))
                    .requestModifier(KFHeaders.modifier)
                    .placeholder {
                        Circle()
                            .fill(Color.gray3)
                    }
                    .cacheOriginalImage()
                    .resizable()
                    .aspectRatio(contentMode: .fill)
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
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            Button(action: onLikeTapped) {
                HStack(spacing: 4) {
                    Image(systemName: product.isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 16))
                        .foregroundColor(product.isLiked ? .pink1 : .gray1)

                    Text("\(product.likeCount)")
                        .Body2()
                        .foregroundColor(.gray1)
                }
            }

            HStack(spacing: 4) {
                Image(systemName: "bubble.right")
                    .font(.system(size: 16))
                    .foregroundColor(.gray1)

                Text("\(product.commentCount)")
                    .Body2()
                    .foregroundColor(.gray1)
            }

            Spacer()
        }
        .padding(.top, 6)
        .padding(.bottom, 2)
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
                    KFImage(URL(string: "\(NetworkConfig.baseURL)/v1\(imageURL)"))
                        .requestModifier(KFHeaders.modifier)
                        .placeholder {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.gray5)
                                .frame(width: itemWidth, height: itemWidth)
                        }
                        .cacheOriginalImage()
                        .fade(duration: 0.2)
                        .resizable()
                        .scaledToFit()
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

            VStack(alignment: .leading, spacing: 2) {
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

                Text(product.formattedDate)
                    .Body2()
                    .foregroundColor(.gray2)
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
