//
//  ChatRealmService.swift
//  Moda
//
//  Created by 금가경 on 11/29/25.
//

import Foundation
import RealmSwift

/// 채팅 메시지 로컬 저장소 구현체
actor ChatRealmService: ChatRealmServiceProtocol {
    static let shared = ChatRealmService()

    private let configuration: Realm.Configuration

    private init() {
        var config = Realm.Configuration.defaultConfiguration
        config.schemaVersion = 1
        config.migrationBlock = { migration, oldSchemaVersion in
            // 마이그레이션 로직은 RealmMigration에서 처리
        }
        self.configuration = config

        do {
            _ = try Realm(configuration: config)
        } catch {
            fatalError("Realm initialization failed: \(error)")
        }
    }

    private func getRealm() throws -> Realm {
        return try Realm(configuration: configuration)
    }

    func saveMessage(_ message: ChatMessageObject) throws {
        let realm = try getRealm()
        try realm.write {
            realm.add(message, update: .modified)
        }
    }

    func saveMessages(_ messages: [ChatMessageObject]) throws {
        let realm = try getRealm()
        try realm.write {
            for message in messages {
                realm.add(message, update: .modified)
            }
        }
    }

    func getMessages(roomId: String, limit: Int, currentUserId: String) -> [ChatMessage] {
        guard let realm = try? getRealm() else { return [] }

        let results = realm.objects(ChatMessageObject.self)
            .filter("roomId == %@", roomId)
            .sorted(byKeyPath: "createdAtDate", ascending: false)
            .prefix(limit)

        return Array(results.map { object in
            object.toChatMessage(currentUserId: currentUserId)
        })
    }

    func getLastMessage(roomId: String) -> (chatId: String, createdAt: String)? {
        guard let realm = try? getRealm() else { return nil }

        guard let result = realm.objects(ChatMessageObject.self)
            .filter("roomId == %@", roomId)
            .sorted(byKeyPath: "createdAtDate", ascending: false)
            .first else { return nil }

        return (chatId: result.chatId, createdAt: result.createdAt)
    }

    func getMessagesBefore(roomId: String, beforeDate: Date, limit: Int, currentUserId: String) -> [ChatMessage] {
        guard let realm = try? getRealm() else { return [] }

        let results = realm.objects(ChatMessageObject.self)
            .filter("roomId == %@ AND createdAtDate < %@", roomId, beforeDate)
            .sorted(byKeyPath: "createdAtDate", ascending: false)
            .prefix(limit)

        return Array(results.map { object in
            object.toChatMessage(currentUserId: currentUserId)
        })
    }

    func getMessage(chatId: String) -> ChatMessage? {
        guard let realm = try? getRealm() else { return nil }

        guard let object = realm.object(ofType: ChatMessageObject.self, forPrimaryKey: chatId) else {
            return nil
        }

        let status = ChatMessage.LocalStatus(rawValue: object.localStatus) ?? .synced
        var attachment: ChatMessage.Attachment?

        if let filesJson = object.filesJson,
           let filesData = filesJson.data(using: .utf8),
           let files = try? JSONDecoder().decode([String].self, from: filesData),
           let firstFile = files.first {
            let urlString = firstFile.hasPrefix("http") ? firstFile : "\(NetworkConfig.baseURL)/v1\(firstFile)"
            if let url = URL(string: urlString) {
                attachment = .image(url)
            }
        }

        return ChatMessage(
            id: object.chatId,
            content: object.content ?? "",
            senderId: object.senderId,
            senderName: object.senderNick,
            senderProfileImage: object.senderProfileImage,
            createdAt: object.createdAtDate,
            isMine: false,
            attachment: attachment,
            localStatus: status
        )
    }

    func saveRoom(_ room: ChatRoomObject) throws {
        let realm = try getRealm()
        try realm.write {
            realm.add(room, update: .modified)
        }
    }

    func getRoom(roomId: String) -> ChatRoomObject? {
        guard let realm = try? getRealm() else { return nil }

        guard let result = realm.object(ofType: ChatRoomObject.self, forPrimaryKey: roomId) else {
            return nil
        }

        return ChatRoomObject(value: result)
    }

    @discardableResult
    func deleteOldMessages() throws -> Int {
        let realm = try getRealm()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        let oldMessages = realm.objects(ChatMessageObject.self)
            .filter("createdAtDate < %@", thirtyDaysAgo)

        let count = oldMessages.count

        try realm.write {
            realm.delete(oldMessages)
        }

        return count
    }

    func updateMessageStatus(chatId: String, status: String) throws {
        let realm = try getRealm()

        guard let message = realm.object(ofType: ChatMessageObject.self, forPrimaryKey: chatId) else {
            return
        }

        try realm.write {
            message.localStatus = status
        }
    }

    func deleteMessage(chatId: String) throws {
        let realm = try getRealm()

        guard let message = realm.object(ofType: ChatMessageObject.self, forPrimaryKey: chatId) else {
            return
        }

        try realm.write {
            realm.delete(message)
        }
    }

    func saveRooms(_ rooms: [ChatRoomObject]) throws {
        let realm = try getRealm()
        try realm.write {
            for room in rooms {
                realm.add(room, update: .modified)
            }
        }
    }

    func getAllRooms() -> [ChatRoomObject] {
        guard let realm = try? getRealm() else { return [] }

        let results = realm.objects(ChatRoomObject.self)
            .sorted(byKeyPath: "updatedAtDate", ascending: false)

        return Array(results.map { ChatRoomObject(value: $0) })
    }

    func deleteAllData() throws {
        let realm = try getRealm()

        try realm.write {
            // 모든 채팅 메시지 삭제
            realm.delete(realm.objects(ChatMessageObject.self))
            // 모든 채팅방 삭제
            realm.delete(realm.objects(ChatRoomObject.self))
        }
    }
}
