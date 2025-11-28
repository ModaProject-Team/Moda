//
//  FeedStore.swift
//  Moda
//
//  Created by Suji Jang on 11/16/25.
//

import Foundation
import CoreLocation
import Combine

// MARK: - Store
@MainActor
final class FeedViewStore: NSObject, ObservableObject {
    @Published private(set) var state = FeedViewState()

    private let postAPI: PostAPIProtocol
    private var cancellables = Set<AnyCancellable>()

    private let searchSubject = PassthroughSubject<String, Never>()
    private let likeSubject = PassthroughSubject<String, Never>()
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
        setupCombineBindings()
    }

    private func setupCombineBindings() {
        // 디바운싱 (300ms)
        searchSubject
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)

        likeSubject
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] postId in
                Task { @MainActor in
                    await self?.sendLikeRequest(postId: postId)
                }
            }
            .store(in: &cancellables)
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

        case .toggleLike(let postId):
            toggleLikeWithDebounce(postId: postId)

        case .updateLikeFromExternal(let postId, let isLiked, let likeCount):
            if let index = state.products.firstIndex(where: { $0.id == postId }) {
                state.products[index].isLiked = isLiked
                state.products[index].likeCount = likeCount
            }

        case .updateLocation(let coordinate):
            state.currentLocation = coordinate

        case .search(let query):
            searchProducts(query: query)

        case .clearSearch:
            state.searchText = ""
            state.filteredProducts = []
            state.isSearching = false
        }
    }

    // MARK: - Search
    private func searchProducts(query: String) {
        state.searchText = query

        if query.isEmpty {
            state.filteredProducts = []
            state.isSearching = false
            return
        }

        searchSubject.send(query)
    }

    private func performSearch(query: String) {
        state.isSearching = true
        state.filteredProducts = state.products.filter {
            $0.title.localizedCaseInsensitiveContains(query)
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
            let cursor = refresh ? nil : (state.nextCursor.isEmpty ? nil : state.nextCursor)

            let response = try await postAPI.getPosts(
                next: cursor,
                limit: "20",
                category: nil
            )

            let currentUserId = UserDefaults.standard.string(forKey: "userId")
            var newProducts = response.data.map { $0.toDomain().toPostCard(currentUserId: currentUserId) }

            // 최신순 정렬
            newProducts.sort { $0.createdAt > $1.createdAt }

            if refresh {
                state.products = newProducts
            } else {
                // 중복 제거
                let existingIds = Set(state.products.map { $0.id })
                let uniqueNewProducts = newProducts.filter { !existingIds.contains($0.id) }
                state.products.append(contentsOf: uniqueNewProducts)
            }

            state.nextCursor = response.nextCursor
            state.hasMoreData = !response.nextCursor.isEmpty && response.nextCursor != "0"

            // 검색어가 있으면 검색 결과도 업데이트
            if !state.searchText.isEmpty {
                performSearch(query: state.searchText)
            }

        } catch {
            state.errorMessage = error.localizedDescription
        }

        state.isLoading = false
    }

    private func toggleLikeWithDebounce(postId: String) {
        if let index = state.products.firstIndex(where: { $0.id == postId }) {
            state.products[index].isLiked.toggle()
            let newLikeState = state.products[index].isLiked

            if newLikeState {
                state.products[index].likeCount += 1
            } else {
                state.products[index].likeCount = max(0, state.products[index].likeCount - 1)
            }

            pendingLikeStates[postId] = newLikeState

            likeSubject.send(postId)
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
