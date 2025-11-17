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
    
    @Published private(set) var state = MapState()

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

        case .dismissLocationUpdateFailedAlert:
            state.showLocationUpdateFailedAlert = false

        case .retryLocationUpdate:
            state.showLocationUpdateFailedAlert = false
            if state.authorizationStatus == .authorizedWhenInUse || state.authorizationStatus == .authorizedAlways {
                locationManager.startUpdatingLocation()
            }
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

                print("시스템 위치 서비스: \(state.isLocationServicesEnabled)")
                print("앱 위치 권한: \(state.authorizationStatus.rawValue)")
                print("CLAuthorizationStatus - notDetermined: 0, restricted: 1, denied: 2, authorizedAlways: 3, authorizedWhenInUse: 4")

                // 시스템 위치 서비스가 꺼져있을 때 Alert 표시
                if !isEnabled {
                    state.showLocationServiceDisabledAlert = true
                }
                // 앱 위치 권한이 거부되었거나, 정책상 제한된 경우 Alert 표시
                else if authStatus == .denied || authStatus == .restricted {
                    state.showPermissionDeniedAlert = true
                }
                // 위치 권한이 허용되었을 때 위치 업데이트 시작
                else if authStatus == .authorizedWhenInUse || authStatus == .authorizedAlways {
                    manager.startUpdatingLocation()
                }
                // 권한 미설정 상태일 때 권한 요청
                else if authStatus == .notDetermined && isEnabled {
                    manager.requestWhenInUseAuthorization()
                }
            }
        }
    }

    // 위치 업데이트를 받았을 때 호출
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task {
            await MainActor.run {
                let coordinate = location.coordinate  // 위경도
                state.currentLocation = coordinate

                // 사용자 위치로 카메라 이동
                state.cameraPosition = .region(
                    MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
                    )
                )

                // 계속 들어오는 GPS 업데이트를 중단
                locationManager.stopUpdatingLocation()

                // TODO: 위치 기반 데이터 로드
                print("현재 위치: \(coordinate.latitude), \(coordinate.longitude)")
            }
        }
    }

    // 위치 업데이트 실패 시 호출
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task {
            await MainActor.run {
                print("위치 업데이트 실패: \(error.localizedDescription)")

                state.cameraPosition = MapState.initialCameraPosition
                state.showLocationUpdateFailedAlert = true

                locationManager.stopUpdatingLocation()
            }
        }
    }
}
