import Foundation
import SocketIO
import Combine

protocol ChatSocketServiceProtocol: AnyObject {
    var isConnected: Published<Bool>.Publisher { get }
    var messageReceived: AnyPublisher<ChatMessageResponse, Never> { get }

    func connect(roomId: String)
    func disconnect()
}

final class ChatSocketService: ChatSocketServiceProtocol {
    @Published private var _isConnected = false
    private let messageSubject = PassthroughSubject<ChatMessageResponse, Never>()

    var isConnected: Published<Bool>.Publisher { $_isConnected }
    var messageReceived: AnyPublisher<ChatMessageResponse, Never> {
        messageSubject.eraseToAnyPublisher()
    }

    private let manager: SocketManager
    private var socket: SocketIOClient

    init(baseURL: String = NetworkConfig.baseURL) {
        self.manager = SocketManager(socketURL: URL(string: baseURL)!, config: [.log(false), .compress])
        self.socket = manager.defaultSocket
    }

    func connect(roomId: String) {
        let headers = NetworkService.buildHeaders()
        let namespace = buildNamespace(roomId: roomId)

        manager.disconnect()
        socket = manager.socket(forNamespace: namespace)
        manager.setConfigs([.extraHeaders(headers), .log(false), .compress])

        setupEventHandlers()
        socket.connect()
    }

    func disconnect() {
        manager.disconnect()
        _isConnected = false
    }

    private func buildNamespace(roomId: String) -> String {
        return "/chats-\(roomId)"
    }

    private func setupEventHandlers() {
        socket.on(clientEvent: .connect) { [weak self] _, _ in
            self?._isConnected = true
        }

        socket.on(clientEvent: .disconnect) { [weak self] _, _ in
            self?._isConnected = false
        }

        socket.on(clientEvent: .error) { [weak self] _, _ in
            self?._isConnected = false
        }

        socket.on("chat") { [weak self] dataArray, _ in
            guard let self else { return }

            if let message = self.parseMessage(from: dataArray) {
                self.messageSubject.send(message)
            }
        }
    }

    private func parseMessage(from dataArray: [Any]) -> ChatMessageResponse? {
        if let dict = dataArray.first as? [String: Any] {
            return parseFromDictionary(dict)
        } else if let str = dataArray.first as? String {
            return parseFromString(str)
        }
        return nil
    }

    private func parseFromDictionary(_ dict: [String: Any]) -> ChatMessageResponse? {
        guard let json = try? JSONSerialization.data(withJSONObject: dict, options: []),
              let dto = try? JSONDecoder().decode(ChatMessageResponse.self, from: json) else {
            return nil
        }
        return dto
    }

    private func parseFromString(_ str: String) -> ChatMessageResponse? {
        guard let data = str.data(using: .utf8),
              let dto = try? JSONDecoder().decode(ChatMessageResponse.self, from: data) else {
            return nil
        }
        return dto
    }
}
