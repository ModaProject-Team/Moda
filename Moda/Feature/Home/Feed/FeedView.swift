//
//  FeedView.swift
//  Moda
//
//  Created by 금가경 on 11/16/25.
//

import SwiftUI
import Kingfisher
import CoreLocation
import Combine

// MARK: - State
struct FeedViewState {
    var products: [PostCard] = []
    var userName = "장수지"
    var categories = ["전체", "sell"]
    var selectedCategory: String = "전체"

    // Pagination
    var nextCursor: String = ""
    var isLoading: Bool = false
    var hasMoreData: Bool = true

    // Location
    var currentLocation: CLLocationCoordinate2D?

    // Error
    var errorMessage: String?
}

// MARK: - Intent
enum FeedIntent {
    case onAppear
    case loadMore
    case refresh
    case selectCategory(String)
    case toggleLike(String)
    case updateLocation(CLLocationCoordinate2D)
}

// MARK: - Store
@MainActor
final class FeedViewStore: NSObject, ObservableObject {
    @Published private(set) var state = FeedViewState()

    private let postAPI: PostAPIProtocol
    private var likeDebounceTimers: [String: Timer] = [:]
    private var pendingLikeStates: [String: Bool] = [:]

    lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        return manager
    }()

    init(postAPI: PostAPIProtocol = PostAPI.shared) {
        self.postAPI = postAPI
        super.init()
    }

    func send(_ intent: FeedIntent) {
        switch intent {
        case .onAppear:
            setupLocationManager()
            if state.products.isEmpty {
                Task { await loadPosts(refresh: true) }
            }

        case .loadMore:
            guard !state.isLoading && state.hasMoreData else { return }
            Task { await loadPosts(refresh: false) }

        case .refresh:
            Task { await loadPosts(refresh: true) }

        case .selectCategory(let category):
            state.selectedCategory = category
            Task { await loadPosts(refresh: true) }

        case .toggleLike(let postId):
            toggleLikeWithDebounce(postId: postId)

        case .updateLocation(let coordinate):
            state.currentLocation = coordinate
        }
    }

    // MARK: - API Calls
    private func loadPosts(refresh: Bool) async {
        if refresh {
            state.nextCursor = ""
            state.hasMoreData = true
        }

        guard state.hasMoreData else { return }

        state.isLoading = true
        state.errorMessage = nil

        do {
            let category: [String]? = state.selectedCategory == "전체" ? ["sell"] : [state.selectedCategory]
            let cursor = refresh ? nil : (state.nextCursor.isEmpty ? nil : state.nextCursor)

            let response = try await postAPI.getPosts(
                next: cursor,
                limit: "20",
                category: category
            )

            let currentUserId = UserDefaults.standard.string(forKey: "userId")
            let newProducts = response.data.map { $0.toDomain().toPostCard(currentUserId: currentUserId) }

            if refresh {
                state.products = newProducts
            } else {
                state.products.append(contentsOf: newProducts)
            }

            state.nextCursor = response.nextCursor
            state.hasMoreData = !response.nextCursor.isEmpty && response.nextCursor != "0"

        } catch {
            state.errorMessage = error.localizedDescription
            print("피드 로드 실패: \(error.localizedDescription)")
        }

        state.isLoading = false
    }

    // MARK: - Like with Debouncing
    private func toggleLikeWithDebounce(postId: String) {
        // 즉시 UI 업데이트
        if let index = state.products.firstIndex(where: { $0.id == postId }) {
            state.products[index].isLiked.toggle()
            let newLikeState = state.products[index].isLiked

            // 좋아요 수 즉시 반영
            if newLikeState {
                state.products[index].likeCount += 1
            } else {
                state.products[index].likeCount = max(0, state.products[index].likeCount - 1)
            }

            pendingLikeStates[postId] = newLikeState

            // 기존 타이머 취소
            likeDebounceTimers[postId]?.invalidate()

            // 300ms 디바운싱
            likeDebounceTimers[postId] = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    await self?.sendLikeRequest(postId: postId)
                }
            }
        }
    }

    private func sendLikeRequest(postId: String) async {
        guard let likeStatus = pendingLikeStates[postId] else { return }

        do {
            _ = try await postAPI.likePost(postId: postId, likeStatus: likeStatus)
            pendingLikeStates.removeValue(forKey: postId)
        } catch {
            // 실패 시 UI 롤백
            if let index = state.products.firstIndex(where: { $0.id == postId }) {
                state.products[index].isLiked.toggle()
                
                if state.products[index].isLiked {
                    state.products[index].likeCount += 1
                } else {
                    state.products[index].likeCount = max(0, state.products[index].likeCount - 1)
                }
            }
            print("좋아요 요청 실패: \(error.localizedDescription)")
        }
    }

    private func setupLocationManager() {
        _ = locationManager
    }
}

// MARK: - CLLocationManagerDelegate
extension FeedViewStore: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let status = manager.authorizationStatus
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.startUpdatingLocation()
            } else if status == .notDetermined {
                manager.requestWhenInUseAuthorization()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            send(.updateLocation(location.coordinate))
            manager.stopUpdatingLocation()
        }
    }
}

// MARK: - View
struct FeedView: View {
    @StateObject private var store = FeedViewStore()
    @EnvironmentObject var navigator: AppNavigator

    var body: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 16
            let horizontalPadding: CGFloat = 16
            let itemWidth = (geometry.size.width - horizontalPadding * 2 - spacing) / 2

            ZStack {
                Color.white
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        logoSection
                        categoryFilterSection
                        userInfoCard
                        productSectionView(itemWidth: itemWidth, spacing: spacing, horizontalPadding: horizontalPadding)

                        if store.state.isLoading && !store.state.products.isEmpty {
                            ProgressView()
                                .padding()
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
                .refreshable {
                    store.send(.refresh)
                }

                uploadButton
            }
        }
        .onAppear {
            store.send(.onAppear)
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
                    CategoryChip(
                        title: category,
                        isSelected: store.state.selectedCategory == category
                    ) {
                        store.send(.selectCategory(category))
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

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

    @ViewBuilder
    private func productSectionView(itemWidth: CGFloat, spacing: CGFloat, horizontalPadding: CGFloat) -> some View {
        if store.state.products.isEmpty && store.state.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, 50)
        } else if store.state.products.isEmpty {
            Text("게시글이 없습니다.")
                .Body1()
                .foregroundColor(.gray2)
                .frame(maxWidth: .infinity)
                .padding(.top, 50)
        } else {
            HStack(alignment: .top, spacing: spacing) {
                // 왼쪽 열
                VStack(spacing: 12) {
                    ForEach(Array(store.state.products.enumerated().filter { $0.offset % 2 == 0 }), id: \.element.id) { index, product in
                        PostCardView(
                            product: product,
                            itemWidth: itemWidth,
                            currentLocation: store.state.currentLocation,
                            onLikeTapped: {
                                store.send(.toggleLike(product.id))
                            }
                        )
                        .onAppear {
                            if index >= store.state.products.count - 4 {
                                store.send(.loadMore)
                            }
                        }
                    }
                }
                .frame(width: itemWidth)

                // 오른쪽 열
                VStack(spacing: 12) {
                    ForEach(Array(store.state.products.enumerated().filter { $0.offset % 2 == 1 }), id: \.element.id) { index, product in
                        PostCardView(
                            product: product,
                            itemWidth: itemWidth,
                            currentLocation: store.state.currentLocation,
                            onLikeTapped: {
                                store.send(.toggleLike(product.id))
                            }
                        )
                        .onAppear {
                            if index >= store.state.products.count - 4 {
                                store.send(.loadMore)
                            }
                        }
                    }
                }
                .frame(width: itemWidth)
            }
            .padding(.horizontal, horizontalPadding)
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

// MARK: - Supporting Views
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
    let itemWidth: CGFloat
    let currentLocation: CLLocationCoordinate2D?
    let onLikeTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            imageSection
            profileSection
            infoSection
        }
        .frame(width: itemWidth, alignment: .leading)
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

            Button(action: onLikeTapped) {
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
        Group {
            if let imageURL = product.imageURL, !imageURL.isEmpty {
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
                    .aspectRatio(contentMode: .fit)
                    .frame(width: itemWidth)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.gray5)
                    .frame(width: itemWidth, height: itemWidth)
            }
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

                    Text("·")
                        .Body2()
                        .foregroundColor(.gray2)
                }

                if let location = product.formattedLocation {
                    Text(location)
                        .Body2()
                        .foregroundColor(.gray2)
                        .lineLimit(1)

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

#Preview {
    FeedView()
        .environmentObject(AppNavigator.shared)
}
