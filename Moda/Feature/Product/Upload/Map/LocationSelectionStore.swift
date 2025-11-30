//
//  LocationSelectionStore.swift
//  Moda
//
//  Created by Suji Jang on 11/22/24.
//

import SwiftUI
import MapKit
import CoreLocation
import UIKit

@MainActor
final class LocationSelectionStore: NSObject, ObservableObject {

    @Published private(set) var state = LocationSelectionState()

    lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        return manager
    }()

    /// 장소 자동완성을 위한 Completer (현재 미사용, 추후 확장 가능)
    private let localSearchCompleter = MKLocalSearchCompleter()

    // 위치 선택 완료 시 장소명, 위도, 경도를 전달
    func setCompletionHandler(_ handler: @escaping (String, Double, Double) -> Void) {
        state.onLocationSelected = handler
    }

    func send(_ intent: LocationSelectionIntent) {
        switch intent {

        case .updateCameraPosition(let position):
            // 지도 카메라 위치 직접 업데이트 (드래그/줌 시)
            state.cameraPosition = position

        case .moveToLocation(let coordinate):
            // 특정 좌표로 지도 이동 (검색 결과 선택 시 등)
            state.selectedCoordinate = coordinate
            state.cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    // latitudeDelta/longitudeDelta: 작을수록 확대 (1km 범위)
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )

        case .updateSelectedCoordinate(let coordinate):
            // 지도 이동 완료 시 중앙 좌표를 선택된 좌표로 업데이트
            state.selectedCoordinate = coordinate

        case .setupLocationManager:
            _ = locationManager

        case .moveToUserLocation:
            if let currentLocation = state.currentLocation {
                state.selectedCoordinate = currentLocation
                state.cameraPosition = .region(
                    MKCoordinateRegion(
                        center: currentLocation,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                )
            }

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
            // 위치 업데이트 재시도
            state.showLocationUpdateFailedAlert = false
            // 권한이 있을 때만 재시도
            if state.authorizationStatus == .authorizedWhenInUse || state.authorizationStatus == .authorizedAlways {
                locationManager.startUpdatingLocation()
            }
            
        case .searchTextChanged(let text):
            // 검색어 변경 시 State 업데이트
            state.searchText = text
            // 검색어가 비어있으면 결과 초기화
            if text.isEmpty {
                state.searchResults = []
                state.hasSearched = false
            }

        case .performSearch:
            // 검색 실행
            Task {
                await performSearch()
            }

        case .selectSearchResult(let mapItem):
            // 검색 결과 항목 선택 시
            if let coordinate = mapItem.placemark.location?.coordinate {
                // 해당 위치로 지도 이동
                state.selectedCoordinate = coordinate
                state.cameraPosition = .region(
                    MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                )
            }
            // 검색 결과 목록 숨김
            state.searchResults = []
            // 검색창에 선택한 장소명 표시
            state.searchText = mapItem.name ?? ""

        case .clearSearch:
            state.searchText = ""
            state.searchResults = []
            state.hasSearched = false

        case .showPlaceNameInputSheet:
            state.showPlaceNameInput = true

        case .placeNameChanged(let name):
            state.placeName = name

        case .confirmLocation:
            // 최종 확인: 콜백을 통해 ProductUploadView로 데이터 전달
            // (장소명, 위도, 경도) 전달
            state.onLocationSelected?(
                state.placeName,
                state.selectedCoordinate.latitude,
                state.selectedCoordinate.longitude
            )
            state.showPlaceNameInput = false

        case .dismissPlaceNameInput:
            state.showPlaceNameInput = false
        }
    }

    private func performSearch() async {
        guard !state.searchText.isEmpty else { return }

        state.isSearching = true

        // 검색 요청 생성
        let request = MKLocalSearch.Request()
        // naturalLanguageQuery: "강남역", "스타벅스 강남점" 등 자연어 검색
        request.naturalLanguageQuery = state.searchText
        // 현재 선택된 위치 주변을 우선 검색
        request.region = MKCoordinateRegion(
            center: state.selectedCoordinate,
            // 검색 범위: 0.1도 = 약 11km
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )

        let search = MKLocalSearch(request: request)

        do {
            // 검색 실행
            let response = try await search.start()
            // MKMapItem 배열로 결과 저장
            state.searchResults = response.mapItems
        } catch {
            state.searchResults = []
        }

        state.isSearching = false
        state.hasSearched = true
    }
    
    private func requestLocationPermission() {
        guard state.isLocationServicesEnabled else { return }
        locationManager.requestWhenInUseAuthorization()
    }

    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

extension LocationSelectionStore: CLLocationManagerDelegate {

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task {
            let isEnabled = CLLocationManager.locationServicesEnabled()
            let authStatus = manager.authorizationStatus

            await MainActor.run {
                let previousStatus = state.authorizationStatus

                state.isLocationServicesEnabled = isEnabled
                state.authorizationStatus = authStatus

                // 권한 상태가 실제로 변경되었을 때만 alert 표시
                if !isEnabled && previousStatus != authStatus {
                    state.showLocationServiceDisabledAlert = true
                } else if (authStatus == .denied || authStatus == .restricted) &&
                          previousStatus != .denied && previousStatus != .restricted {
                    state.showPermissionDeniedAlert = true
                } else if authStatus == .authorizedWhenInUse || authStatus == .authorizedAlways {
                    // 이미 위치를 가져온 경우 다시 업데이트하지 않음
                    if state.currentLocation == nil {
                        manager.startUpdatingLocation()
                    }
                } else if authStatus == .notDetermined && isEnabled {
                    manager.requestWhenInUseAuthorization()
                }
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task {
            await MainActor.run {
                let coordinate = location.coordinate

                state.currentLocation = coordinate
                state.selectedCoordinate = coordinate

                state.cameraPosition = .region(
                    MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                )

                locationManager.stopUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task {
            await MainActor.run {
                // 이미 위치를 가져온 경우 에러 무시
                guard state.currentLocation == nil else {
                    locationManager.stopUpdatingLocation()
                    return
                }

                // CLError 처리
                if let clError = error as? CLError {
                    switch clError.code {
                    case .denied, .network, .locationUnknown:
                        state.showLocationUpdateFailedAlert = true
                    default:
                        break
                    }
                }

                locationManager.stopUpdatingLocation()
            }
        }
    }
}
