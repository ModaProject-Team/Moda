//
//  TabItem.swift
//  Moda
//
//  Created by 금가경 on 11/16/25.
//

import SwiftUI

enum TabItem: Int, CaseIterable {
    case home
    case map
    case friends
    case chat
    case setting

    var icon: String {
        switch self {
        case .home:
            return "house"
        case .map:
            return "map"
        case .friends:
            return "person.2"
        case .chat:
            return "message"
        case .setting:
            return "gearshape"
        }
    }

    var selectedIcon: String {
        switch self {
        case .home:
            return "house.fill"
        case .map:
            return "map.fill"
        case .friends:
            return "person.2.fill"
        case .chat:
            return "message.fill"
        case .setting:
            return "gearshape.fill"
        }
    }
}
