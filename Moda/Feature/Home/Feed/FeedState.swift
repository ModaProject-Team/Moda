//
//  FeedState.swift
//  Moda
//
//  Created by Suji Jang on 11/16/25.
//

import Foundation
import CoreLocation

// MARK: - State
struct FeedViewState {
    var products: [PostCard] = []
    var filteredProducts: [PostCard] = []
    var userName = "장수지"
    var categories = ["전체", "중고거래", "나눔"]
    var selectedCategory: String = "전체"

    // Search
    var searchText: String = ""
    var isSearching: Bool = false

    // Pagination
    var nextCursor: String = ""
    var isLoading: Bool = true
    var hasMoreData: Bool = true

    // Location
    var currentLocation: CLLocationCoordinate2D?

    // Error
    var errorMessage: String?

    // 맞팔 친구 ID 목록
    var mutualFriendIds: Set<String> = []

    // 검색 결과 또는 카테고리 필터링된 목록 반환
    var displayProducts: [PostCard] {
        if !searchText.isEmpty {
            return filteredProducts
        }

        // 카테고리 필터링
        switch selectedCategory {
        case "중고거래":
            return products.filter { ($0.price ?? 0) > 0 }
        case "나눔":
            return products.filter { ($0.price ?? 0) == 0 }
        default: // "전체"
            return products
        }
    }
}
