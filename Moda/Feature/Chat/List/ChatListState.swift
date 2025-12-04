//
//  ChatListState.swift
//  Moda
//
//  Created by 금가경 on 11/29/25.
//

import Foundation

struct ChatRoom: Identifiable {
    let id: String
    let participantName: String
    let participantProfileImage: String?
    let lastMessage: String
    let lastMessageTime: Date
}

struct ChatListState {
    var chatRooms: [ChatRoom] = []
    var isLoading: Bool = false
    var errorMessage: String?
}
