//
//  ProfileDetailIntent.swift
//  Moda
//
//  Created by 금가경 on 11/29/25.
//

import Foundation

enum ProfileDetailIntent {
    case onAppear
    case selectTab(ProfileTab)
    case editTapped
    case uploadTapped

    case loadMore
    case refresh
    case toggleLike(String)
}
