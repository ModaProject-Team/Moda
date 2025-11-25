import Foundation
import SocketIO

protocol ChatSocketServiceProtocol: AnyObject {
    func connect(roomId: String)
    func disconnect()
    var onConnect: (() -> Void)? { get set }
    var onDisconnect: (() -> Void)? { get set }
    var onError: ((String) -> Void)? { get set }
    var onChat: ((ChatMessageResponse) -> Void)? { get set }
}

final class ChatSocketService: ChatSocketServiceProtocol {
    private let manager: SocketManager
    private let socket: SocketIOClient

    var onConnect: (() -> Void)?
    var onDisconnect: (() -> Void)?
    var onError: ((String) -> Void)?
    var onChat: ((ChatMessageResponse) -> Void)?

    init(baseURL: String = NetworkConfig.baseURL) {
        // 생성 시점에는 네임스페이스를 비워두고, connect(roomId:)에서 재설정합니다.
        self.manager = SocketManager(socketURL: URL(string: baseURL)!, config: [.log(false), .compress])
        // 일단 기본 소켓을 만들지만, 실제 연결은 connect(roomId:)에서 해당 네임스페이스로 다시 설정합니다.
        self.socket = manager.defaultSocket
    }

    func connect(roomId: String) {
        // 기존 핸들러 제거
        socket.off(clientEvent: .connect)
        socket.off("chat")
        socket.off(clientEvent: .disconnect)
        socket.off(clientEvent: .error)

        // 헤더 구성
        var extraHeaders: [String: String] = [
            "SesacKey": NetworkConfig.sesacKey,
            "ProductId": NetworkConfig.productId
        ]
        if let token = TokenManager.shared.accessToken, !token.isEmpty {
            extraHeaders["Authorization"] = token
        }

        // 네임스페이스: /chats-{roomId}
        let namespace = "/chats-\(roomId)"

        // 기존 소켓을 닫고 네임스페이스 소켓을 새로 가져옵니다.
        manager.disconnect()
        let nspSocket = manager.socket(forNamespace: namespace)

        // 헤더 적용을 위해 config 업데이트
        manager.setConfigs([.extraHeaders(extraHeaders), .log(false), .compress])

        // 이벤트 핸들링
        nspSocket.on(clientEvent: .connect) { [weak self] data, ack in
            self?.onConnect?()
        }
        nspSocket.on("chat") { [weak self] dataArray, ack in
            guard let self else { return }
            // dataArray[0]가 JSON 객체일 것으로 가정
            if let dict = dataArray.first as? [String: Any] {
                do {
                    let json = try JSONSerialization.data(withJSONObject: dict, options: [])
                    let dto = try JSONDecoder().decode(ChatMessageResponse.self, from: json)
                    self.onChat?(dto)
                } catch {
                    self.onError?("소켓 메시지 파싱 실패: \(error.localizedDescription)")
                }
            } else if let str = dataArray.first as? String, let data = str.data(using: .utf8) {
                do {
                    let dto = try JSONDecoder().decode(ChatMessageResponse.self, from: data)
                    self.onChat?(dto)
                } catch {
                    self.onError?("소켓 메시지 파싱 실패: \(error.localizedDescription)")
                }
            } else {
                self.onError?("알 수 없는 소켓 데이터 형식")
            }
        }
        nspSocket.on(clientEvent: .error) { [weak self] data, ack in
            self?.onError?("소켓 에러: \(data)")
        }
        nspSocket.on(clientEvent: .disconnect) { [weak self] data, ack in
            self?.onDisconnect?()
        }

        // 연결
        nspSocket.connect()
    }

    func disconnect() {
        manager.disconnect()
    }
}
