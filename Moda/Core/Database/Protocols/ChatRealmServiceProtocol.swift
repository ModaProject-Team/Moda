//
//  ChatRealmServiceProtocol.swift
//  Moda
//
//  Created by 금가경 on 11/29/25.
//

import Foundation

/// 채팅 메시지 로컬 저장소 프로토콜
protocol ChatRealmServiceProtocol {
    /// 단일 메시지 저장
    /// - Parameter message: 저장할 메시지 객체
    func saveMessage(_ message: ChatMessageObject) throws

    /// 여러 메시지 일괄 저장
    /// - Parameter messages: 저장할 메시지 배열
    func saveMessages(_ messages: [ChatMessageObject]) throws

    /// 특정 채팅방의 메시지 조회 (최신순)
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    ///   - limit: 조회할 메시지 개수
    /// - Returns: 메시지 배열
    func getMessages(roomId: String, limit: Int) -> [ChatMessageObject]

    /// 특정 채팅방의 가장 최근 메시지 조회
    /// - Parameter roomId: 채팅방 ID
    /// - Returns: 가장 최근 메시지 (없으면 nil)
    func getLastMessage(roomId: String) -> ChatMessageObject?

    /// 특정 시점 이전의 메시지 조회 (페이지네이션)
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    ///   - beforeDate: 기준 날짜
    ///   - limit: 조회할 메시지 개수
    /// - Returns: 메시지 배열
    func getMessagesBefore(roomId: String, beforeDate: Date, limit: Int) -> [ChatMessageObject]

    /// 채팅방 메타데이터 저장/업데이트
    /// - Parameter room: 채팅방 객체
    func saveRoom(_ room: ChatRoomObject) throws

    /// 채팅방 메타데이터 조회
    /// - Parameter roomId: 채팅방 ID
    /// - Returns: 채팅방 객체 (없으면 nil)
    func getRoom(roomId: String) -> ChatRoomObject?

    /// 30일 이상 오래된 메시지 삭제
    /// - Returns: 삭제된 메시지 개수
    @discardableResult
    func deleteOldMessages() throws -> Int

    /// 특정 메시지의 상태 업데이트
    /// - Parameters:
    ///   - chatId: 메시지 ID
    ///   - status: 새로운 상태 (synced, sending, failed)
    func updateMessageStatus(chatId: String, status: String) throws
}
