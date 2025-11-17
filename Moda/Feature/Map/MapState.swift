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
    var currentSpan: MKCoordinateSpan
    var isLocationServicesEnabled: Bool
    var authorizationStatus: CLAuthorizationStatus
    var showPermissionDeniedAlert: Bool
    var showLocationServiceDisabledAlert: Bool
    var showLocationUpdateFailedAlert: Bool
    var currentLocation: CLLocationCoordinate2D?
    var posts: [PostAnnotation]
    var selectedPostId: String?
    var selectedPostIndex: Int?

    // 경도 기준으로 정렬된 게시물 배열
    var sortedPosts: [PostAnnotation] {
        posts.sorted { $0.longitude < $1.longitude }
    }

    //TODO: GPS 또는 앱 위치 설정이 꺼져있을 경우에 사용하기
    static let initialCameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780), // 서울 시청
            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        )
    )

    init(
        cameraPosition: MapCameraPosition = MapState.initialCameraPosition,
        currentSpan: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015),
        isLocationServicesEnabled: Bool = false,
        authorizationStatus: CLAuthorizationStatus = .notDetermined,
        showPermissionDeniedAlert: Bool = false,
        showLocationServiceDisabledAlert: Bool = false,
        showLocationUpdateFailedAlert: Bool = false,
        currentLocation: CLLocationCoordinate2D? = nil,
        posts: [PostAnnotation] = PostAnnotation.mockData,
        selectedPostId: String? = nil,
        selectedPostIndex: Int? = nil
    ) {
        self.cameraPosition = cameraPosition
        self.currentSpan = currentSpan
        self.isLocationServicesEnabled = isLocationServicesEnabled
        self.authorizationStatus = authorizationStatus
        self.showPermissionDeniedAlert = showPermissionDeniedAlert
        self.showLocationServiceDisabledAlert = showLocationServiceDisabledAlert
        self.showLocationUpdateFailedAlert = showLocationUpdateFailedAlert
        self.currentLocation = currentLocation
        self.posts = posts
        self.selectedPostId = selectedPostId
        self.selectedPostIndex = selectedPostIndex
    }
}
