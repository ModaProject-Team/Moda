//
//  MapState.swift
//  Moda
//
//  Created by Suji Jang on 11/15/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapState {
    var cameraPosition: MapCameraPosition
    var isLocationServicesEnabled: Bool
    var authorizationStatus: CLAuthorizationStatus
    var showPermissionDeniedAlert: Bool
    var showLocationServiceDisabledAlert: Bool
    var showLocationUpdateFailedAlert: Bool
    var currentLocation: CLLocationCoordinate2D?

    //TODO: GPS 또는 앱 위치 설정이 꺼져있을 경우에 사용하기
    static let initialCameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780), // 서울 시청
            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        )
    )

    init(
        cameraPosition: MapCameraPosition = MapState.initialCameraPosition,
        isLocationServicesEnabled: Bool = false,
        authorizationStatus: CLAuthorizationStatus = .notDetermined,
        showPermissionDeniedAlert: Bool = false,
        showLocationServiceDisabledAlert: Bool = false,
        showLocationUpdateFailedAlert: Bool = false,
        currentLocation: CLLocationCoordinate2D? = nil
    ) {
        self.cameraPosition = cameraPosition
        self.isLocationServicesEnabled = isLocationServicesEnabled
        self.authorizationStatus = authorizationStatus
        self.showPermissionDeniedAlert = showPermissionDeniedAlert
        self.showLocationServiceDisabledAlert = showLocationServiceDisabledAlert
        self.showLocationUpdateFailedAlert = showLocationUpdateFailedAlert
        self.currentLocation = currentLocation
    }
}
