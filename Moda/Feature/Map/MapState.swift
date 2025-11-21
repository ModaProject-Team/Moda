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
    var selectedClusterPostIds: Set<String>?
    var showClusterSheet: Bool
    var clusterSheetPosts: [PostAnnotation]
    var isLoadingPosts: Bool
    var postLoadError: String?
    var showSearchButton: Bool
    var mapCenterCoordinate: CLLocationCoordinate2D?
    var hasLoadedInitialPosts: Bool

    // 경도 기준으로 정렬된 게시물 배열
    var sortedPosts: [PostAnnotation] {
        posts.sorted { $0.longitude < $1.longitude }
    }

    // 클러스터링된 지도 아이템
    var mapItems: [MapItem] {
        // 줌 레벨에 따른 클러스터링 거리 계산
        // currentSpan.latitudeDelta가 클수록 = 줌 아웃 = 더 넓은 범위 = 더 많이 클러스터링
        let clusterDistance = currentSpan.latitudeDelta * 0.08 // 줌 레벨의 8%

        var processed: Set<String> = []
        var items: [MapItem] = []

        for post in posts {
            // 이미 처리된 게시물은 건너뛰기
            if processed.contains(post.id) {
                continue
            }

            // 현재 게시물을 기준으로 클러스터 시작
            var cluster: [PostAnnotation] = [post]
            processed.insert(post.id)

            // 다른 게시물들과의 거리 계산
            for other in posts where !processed.contains(other.id) {
                let distance = sqrt(
                    pow(post.latitude - other.latitude, 2) +
                    pow(post.longitude - other.longitude, 2)
                )

                // 거리가 threshold(임계값)보다 가까우면 클러스터에 추가
                if distance < clusterDistance {
                    cluster.append(other)
                    processed.insert(other.id)
                }
            }

            // 2개 이상이면 클러스터로, 1개면 개별 핀으로 표시
            if cluster.count > 1 {
                items.append(.cluster(cluster))
            } else {
                items.append(.single(post))
            }
        }

        return items
    }

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
        posts: [PostAnnotation] = [],
        selectedPostId: String? = nil,
        selectedPostIndex: Int? = nil,
        selectedClusterPostIds: Set<String>? = nil,
        showClusterSheet: Bool = false,
        clusterSheetPosts: [PostAnnotation] = [],
        isLoadingPosts: Bool = false,
        postLoadError: String? = nil,
        showSearchButton: Bool = false,
        mapCenterCoordinate: CLLocationCoordinate2D? = nil,
        hasLoadedInitialPosts: Bool = false
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
        self.selectedClusterPostIds = selectedClusterPostIds
        self.showClusterSheet = showClusterSheet
        self.clusterSheetPosts = clusterSheetPosts
        self.isLoadingPosts = isLoadingPosts
        self.postLoadError = postLoadError
        self.showSearchButton = showSearchButton
        self.mapCenterCoordinate = mapCenterCoordinate
        self.hasLoadedInitialPosts = hasLoadedInitialPosts
    }
}
