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
    var userName = "장수지"
    var categories = ["전체", "중고거래", "나눔"]
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
