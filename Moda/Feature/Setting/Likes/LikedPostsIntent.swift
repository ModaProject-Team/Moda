//
//  LikedPostsIntent.swift
//  Moda
//
//  Created by Suji Jang on 11/24/24.
//

import Foundation

enum LikedPostsIntent {
    case onAppear
    case loadMore
    case refresh
    case toggleLike(String)
    case postTapped(String)
}
