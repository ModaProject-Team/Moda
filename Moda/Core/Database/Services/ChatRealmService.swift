//
//  ChatRealmService.swift
//  Moda
//
//  Created by 금가경 on 11/29/25.
//

import Foundation
import RealmSwift

/// 채팅 메시지 로컬 저장소 구현체
final class ChatRealmService: ChatRealmServiceProtocol {
    static let shared = ChatRealmService()

    private let realm: Realm

    private init() {
        do {
            var config = Realm.Configuration.defaultConfiguration
            config.schemaVersion = 1
            config.migrationBlock = { migration, oldSchemaVersion in
                // 마이그레이션 로직은 RealmMigration에서 처리
            }

            self.realm = try Realm(configuration: config)
            print("✅ Realm initialized at: \(realm.configuration.fileURL?.path ?? "unknown")")
        } catch {
            fatalError("❌ Realm initialization failed: \(error)")
        }
    }

    func saveMessage(_ message: ChatMessageObject) throws {
        try realm.write {
            realm.add(message, update: .modified)
        }
    }

    func saveMessages(_ messages: [ChatMessageObject]) throws {
        try realm.write {
            for message in messages {
                realm.add(message, update: .modified)
            }
        }
    }

    func getMessages(roomId: String, limit: Int) -> [ChatMessageObject] {
        let results = realm.objects(ChatMessageObject.self)
            .filter("roomId == %@", roomId)
            .sorted(byKeyPath: "createdAtDate", ascending: false)
            .prefix(limit)

        return Array(results)
    }

    func getLastMessage(roomId: String) -> ChatMessageObject? {
        return realm.objects(ChatMessageObject.self)
            .filter("roomId == %@", roomId)
            .sorted(byKeyPath: "createdAtDate", ascending: false)
            .first
    }

    func getMessagesBefore(roomId: String, beforeDate: Date, limit: Int) -> [ChatMessageObject] {
        let results = realm.objects(ChatMessageObject.self)
            .filter("roomId == %@ AND createdAtDate < %@", roomId, beforeDate)
            .sorted(byKeyPath: "createdAtDate", ascending: false)
            .prefix(limit)

        return Array(results)
    }

    func saveRoom(_ room: ChatRoomObject) throws {
        try realm.write {
            realm.add(room, update: .modified)
        }
    }

    func getRoom(roomId: String) -> ChatRoomObject? {
        return realm.object(ofType: ChatRoomObject.self, forPrimaryKey: roomId)
    }

    @discardableResult
    func deleteOldMessages() throws -> Int {
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
        guard let message = realm.object(ofType: ChatMessageObject.self, forPrimaryKey: chatId) else {
            return
        }

        try realm.write {
            message.localStatus = status
        }
    }
}
