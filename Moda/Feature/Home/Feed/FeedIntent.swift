//
//  FeedIntent.swift
//  Moda
//
//  Created by Suji Jang on 11/16/25.
//

import Foundation
import CoreLocation

enum FeedIntent {
    case onAppear
    case onDisappear
    case loadMore
    case refresh
    case selectCategory(String)
    case toggleLike(String)
    case updateLikeFromExternal(postId: String, isLiked: Bool, likeCount: Int)
    case updateLocation(CLLocationCoordinate2D)
    case search(String)
    case clearSearch

    case adMobInitialized
}
