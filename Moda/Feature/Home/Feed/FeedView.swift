//
//  FeedView.swift
//  Moda
//
//  Created by 금가경 on 11/16/25.
//

import SwiftUI

struct FeedViewState {
    var products: [PostCard] = PostCard.mockData
    var userName = "장수지"
    var categories = ["전체", "study", "electronics", "fashion", "books", "living", "sports"]
}

final class FeedViewStore: ObservableObject {
    @Published private(set) var state = FeedViewState()
}

struct FeedView: View {
    @StateObject private var store = FeedViewStore()
    @EnvironmentObject var navigator: AppNavigator

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    logoSection
                    categoryFilterSection
                    userInfoCard
                    productSection
                }
                .padding(.top, 16)
                .padding(.bottom, 100)
            }

            uploadButton
        }
    }

    private var logoSection: some View {
        HStack {
            Image("AppIcon")
                .resizable()
                .scaledToFit()
                .frame(height: 48)

            Spacer()

            Button {
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20))
                    .foregroundColor(.gray1)
            }
        }
        .padding(.horizontal, 16)
    }

    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(store.state.categories, id: \.self) { category in
                    CategoryChip(title: category)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // TODO: - 프로필 구간으로 옮길 예정입니다.
    private var userInfoCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.gray3)
                    .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text(store.state.userName)
                        .H1()
                        .foregroundColor(.gray1)

                    Text("프로필")
                        .Body1()
                        .foregroundColor(.gray2)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                QuickActionButton(icon: "arrow.up.circle.fill", title: "올리기") {
                    navigator.push(.productUpload)
                }
                QuickActionButton(icon: "heart.fill", title: "찜 목록") {
                }
                QuickActionButton(icon: "clock.fill", title: "거래내역") {
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.gray5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.gray4, lineWidth: 0.5)
        )
        .padding(.horizontal, 16)
    }

    private var productSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                LazyVStack(spacing: 12) {
                    ForEach(Array(store.state.products.enumerated()).filter { $0.offset % 2 == 0 }, id: \.element.id) { _, product in
                        PostCardView(product: product, store: store)
                    }
                }

                LazyVStack(spacing: 12) {
                    ForEach(Array(store.state.products.enumerated()).filter { $0.offset % 2 == 1 }, id: \.element.id) { _, product in
                        PostCardView(product: product, store: store)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var uploadButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    navigator.push(.productUpload)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("글쓰기")
                            .H2()
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color.blue1)
                    )
                }
                .padding(.trailing, 20)
                .padding(.bottom, 80)
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    private var iconColor: Color {
        switch icon {
        case "arrow.up.circle.fill":
            return Color.green1
        case "heart.fill":
            return Color.pink1
        case "clock.fill":
            return Color.blue1
        default:
            return Color.gray1
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
                    .fill(Color.white.opacity(0.6))
            )
        }
    }
}

struct PostCardView: View {
    let product: PostCard
    @ObservedObject var store: FeedViewStore

    private var imageHeight: CGFloat {
        let heights: [CGFloat] = [100, 115, 130, 140, 120, 110]
        let index = abs(product.id.hashValue) % heights.count
        return heights[index]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            imageSection
            profileSection
            infoSection
        }
    }

    private var profileSection: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.gray3)
                .frame(width: 24, height: 24)

            Text(product.creator.nickname)
                .Body1()
                .foregroundColor(.gray1)

            Spacer()

            Button {
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: product.isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(product.isLiked ? Color.pink1 : Color.gray1)

                    Text("\(product.likeCount)")
                        .Body1()
                        .foregroundColor(.gray1)
                }
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var imageSection: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.gray5)
            .frame(height: imageHeight)
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(product.title)
                .Body1()
                .foregroundColor(.gray1)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 4) {
                if let distance = product.formattedDistance() {
                    Text(distance)
                        .Body2()
                        .foregroundColor(.gray2)

                    Text("·")
                        .Body2()
                        .foregroundColor(.gray2)
                }

                if let location = product.formattedLocation {
                    Text(location)
                        .Body2()
                        .foregroundColor(.gray2)

                    Text("·")
                        .Body2()
                        .foregroundColor(.gray2)
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

    private var isSelected: Bool {
        title == "전체"
    }

    var body: some View {
        Button {
        } label: {
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

#Preview {
    FeedView()
        .environmentObject(AppNavigator.shared)
}
