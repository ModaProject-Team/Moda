//
//  FriendAddIntent.swift
//  Moda
//
//  Created by 금가경 on 11/29/25.
//

import Foundation

enum FriendAddIntent {
    case onAppear
    case queryChanged(String)
    case clearTapped
    case searchSubmitted
    case rowTapped(FriendSearchItem)

    case friendAddButtonTapped
    case cardCloseTapped
}
