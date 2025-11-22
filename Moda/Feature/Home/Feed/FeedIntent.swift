//
//  FeedIntent.swift
//  Moda
//
//  Created by Suji Jang on 11/16/25.
//

import Foundation
import CoreLocation

// MARK: - Intent
enum FeedIntent {
    case onAppear
    case loadMore
    case refresh
    case selectCategory(String)
    case toggleLike(String)
    case updateLocation(CLLocationCoordinate2D)
}
