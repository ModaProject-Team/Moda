//
//  ChatRoomState.swift
//  Moda
//
//  Created by 금가경 on 11/29/25.
//

import Foundation

struct ChatMessage: Identifiable {
    let id: String
    let content: String
    let senderId: String
    let senderName: String
    let senderProfileImage: String?
    let createdAt: Date
    let isMine: Bool
    let attachment: Attachment?

    enum Attachment: Equatable {
        case image(URL)
    }
}

struct ChatRoomState {
    var messages: [ChatMessage] = []
    var inputText: String = ""
    var participantName: String = ""
    var isLoading: Bool = false
    var errorMessage: String?

    var showAttachmentSheet: Bool = false
    var showImagePicker: Bool = false

    var showSendConfirmAlert: Bool = false
    var pendingImageData: Data? = nil
    var pendingType: PendingType = .none

    var showImageViewer: Bool = false
    var selectedImageURL: URL? = nil

    enum PendingType { case image, none }
}
