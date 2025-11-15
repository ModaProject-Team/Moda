//
//  MapStore.swift
//  Moda
//
//  Created by Suji Jang on 11/15/25.
//

import SwiftUI
import MapKit
import CoreLocation

@MainActor
final class MapStore: NSObject, ObservableObject {
    @Published private(set) var state = MapState(
        cameraPosition: MapState.initialCameraPosition,
        isLocationServicesEnabled: false,
        showLocationAlert: false
    )

    lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        return manager
    }()

    func send(_ intent: MapIntent) {
        switch intent {
        case .updateCameraPosition(let position):
            state.cameraPosition = position

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

        case .dismissLocationAlert:
            state.showLocationAlert = false
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension MapStore: CLLocationManagerDelegate {
    
    // 사용자 권한 상태가 변경된 경우 & CLLocationManager Create (iOS14 이상)
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task {
            let isEnabled = CLLocationManager.locationServicesEnabled()
            await MainActor.run {
                state.isLocationServicesEnabled = isEnabled

                if !isEnabled {
                    state.showLocationAlert = true
                }

                print("시스템 위치 서비스: \(state.isLocationServicesEnabled)")
            }
        }
    }
}
