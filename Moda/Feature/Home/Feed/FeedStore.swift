//
//  FeedStore.swift
//  Moda
//
//  Created by Suji Jang on 11/16/25.
//

import Foundation
import CoreLocation

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
