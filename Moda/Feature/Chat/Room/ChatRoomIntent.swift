//
//  ChatRoomIntent.swift
//  Moda
//
//  Created by 금가경 on 11/29/25.
//

import Foundation

enum ChatRoomIntent {
    case onAppear
    case onDisappear
    case inputTextChanged(String)
    case sendButtonTapped
    case dismissError

    case attachmentButtonTapped
    case pickImage
    case attachmentSheetDismissed

    case imagePicked(Data)
    case imagePickerDismissed

    case showSendConfirm
    case hideSendConfirm

    case confirmSend
    case cancelSend

    case showImageViewer(URL)
    case hideImageViewer

    case retryMessage(String)
    case deleteMessage(String)
    case retryConnection

    case loadMoreMessages

    case appDidEnterBackground
    case appWillEnterForeground
}
