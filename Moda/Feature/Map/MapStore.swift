//
//  MapStore.swift
//  Moda
//
//  Created by Suji Jang on 11/15/25.
//

import SwiftUI
import MapKit
import CoreLocation
import UIKit

@MainActor
final class MapStore: NSObject, ObservableObject {
    @Published private(set) var state = MapState(
        cameraPosition: MapState.initialCameraPosition,
        isLocationServicesEnabled: false,
        authorizationStatus: .notDetermined,  // 0: 사용자가 허용/거부 등 아무것도 설정하지 않은 상태: 보통 앱을 처음 실행했을 때
        showPermissionDeniedAlert: false,
        showLocationServiceDisabledAlert: false
    )

    lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        return manager
    }()

    func send(_ intent: MapIntent) {
        switch intent {
            //TODO: 현재 화면 중심 좌표 -> 지도가 변경될 때 게시물 재로드
        case .updateCameraPosition(let position):
            state.cameraPosition = position

            //TODO: 지도 위치를 강제로 이동
        case .moveToLocation(let coordinate):
            state.cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
                )
            )

        case .loadInitialLocation:
            //TODO: 권한 설정 후 진입 위치 수정하기
            state.cameraPosition = MapState.initialCameraPosition

        case .setupLocationManager:
            //TODO: lazy var의 초기화를 일단 강제로 실행
            _ = locationManager

        case .requestLocationPermission:
            requestLocationPermission()

        case .openAppSettings:
            openAppSettings()

        case .dismissPermissionDeniedAlert:
            state.showPermissionDeniedAlert = false

        case .dismissLocationServiceDisabledAlert:
            state.showLocationServiceDisabledAlert = false
        }
    }

    private func requestLocationPermission() {
        guard state.isLocationServicesEnabled else {
            // 시스템 위치 서비스가 꺼져있으면 권한 요청하지 않음
            return
        }

        // 권한 여부 확인 (허용, 거부, 결정X): notDetermined 상황에서 request
        locationManager.requestWhenInUseAuthorization()
    }

    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension MapStore: CLLocationManagerDelegate {
    
    // 사용자 권한 상태가 변경된 경우 & CLLocationManager Create (iOS14 이상)
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task {
            let isEnabled = CLLocationManager.locationServicesEnabled()
            let authStatus = manager.authorizationStatus

            await MainActor.run {
                state.isLocationServicesEnabled = isEnabled
                state.authorizationStatus = authStatus

                // 시스템 위치 서비스가 꺼져있을 때 Alert 표시
                if !isEnabled {
                    state.showLocationServiceDisabledAlert = true
                }
                // 앱 위치 권한이 거부되었거나, 정책상 제한된 경우 Alert 표시
                else if authStatus == .denied || authStatus == .restricted {
                    state.showPermissionDeniedAlert = true
                }

                print("시스템 위치 서비스: \(state.isLocationServicesEnabled)")
                print("앱 위치 권한: \(state.authorizationStatus.rawValue)")
            }
        }
    }
}
