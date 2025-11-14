//
//  NetworkMonitor.swift
//  Moda
//
//  Created by 금가경 on 11/13/24.
//

import Foundation
import Network

/// 네트워크 연결 상태를 실시간으로 모니터링하는 클래스
///
/// NWPathMonitor를 사용하여 네트워크 연결 상태를 감지하고 변경사항을 알립니다.
final class NetworkMonitor: ObservableObject {
    /// 싱글톤 인스턴스
    static let shared = NetworkMonitor()

    /// 현재 네트워크 연결 상태
    @Published private(set) var isConnected: Bool = true

    /// 현재 연결 타입
    @Published private(set) var connectionType: ConnectionType = .unknown

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor")

    /// 네트워크 연결 타입
    enum ConnectionType {
        /// Wi-Fi 연결
        case wifi
        /// 셀룰러 연결
        case cellular
        /// 이더넷 연결
        case ethernet
        /// 알 수 없음
        case unknown
    }

    private init() {
        monitor = NWPathMonitor()
    }

    /// 네트워크 모니터링 시작
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.updateConnectionType(path)
            }
        }
        monitor.start(queue: queue)
    }

    /// 네트워크 모니터링 중지
    func stopMonitoring() {
        monitor.cancel()
    }

    /// 연결 타입 업데이트
    ///
    /// - Parameter path: NWPath 객체
    private func updateConnectionType(_ path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else {
            connectionType = .unknown
        }
    }
}
