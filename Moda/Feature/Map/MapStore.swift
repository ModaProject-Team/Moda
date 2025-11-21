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

        case .moveToUserLocation:
            if let currentLocation = state.currentLocation {
                state.cameraPosition = .region(
                    MKCoordinateRegion(
                        center: currentLocation,
                        span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
                    )
                )
            }

        case .selectPost(let postId):
            state.selectedPostId = postId

            // 개별 게시물 선택 시 클러스터 선택 해제 및 시트 닫기
            if postId != nil {
                state.selectedClusterPostIds = nil
                state.showClusterSheet = false
                state.clusterSheetPosts = []
            }

            // 경도 기준 정렬된 배열에서 인덱스 찾기
            if let postId = postId {
                state.selectedPostIndex = state.sortedPosts.firstIndex(where: { $0.id == postId })
            } else {
                state.selectedPostIndex = nil
            }

            // 선택된 핀을 지도 중앙으로 이동 (현재 확대 레벨 유지)
            if let postId = postId,
               let selectedPost = state.posts.first(where: { $0.id == postId }) {
                state.cameraPosition = .region(
                    MKCoordinateRegion(
                        center: selectedPost.coordinate,
                        span: state.currentSpan
                    )
                )
            }

        case .selectPostByIndex(let index):
            let sortedPosts = state.sortedPosts
            guard let index = index, index >= 0, index < sortedPosts.count else {
                state.selectedPostId = nil
                state.selectedPostIndex = nil
                return
            }

            let selectedPost = sortedPosts[index]
            state.selectedPostId = selectedPost.id
            state.selectedPostIndex = index

            // 선택된 핀을 지도 중앙으로 이동 (현재 확대 레벨 유지)
            state.cameraPosition = .region(
                MKCoordinateRegion(
                    center: selectedPost.coordinate,
                    span: state.currentSpan
                )
            )

        case .updateSpan(let span):
            state.currentSpan = span

        case .selectCluster(let postIds):
            state.selectedClusterPostIds = postIds
            // 클러스터 선택 시 개별 게시물 선택 해제
            if postIds != nil {
                state.selectedPostId = nil
                state.selectedPostIndex = nil
            }

        case .showClusterSheet(let posts):
            state.clusterSheetPosts = posts
            state.showClusterSheet = true

        case .dismissClusterSheet:
            state.showClusterSheet = false
            state.clusterSheetPosts = []
            // 시트 닫을 때 클러스터 선택도 함께 해제
            state.selectedClusterPostIds = nil

        case .fetchPostsByLocation(let longitude, let latitude, let maxDistance):
            Task {
                await fetchPostsByLocation(longitude: longitude, latitude: latitude, maxDistance: maxDistance)
            }

        case .dismissPostLoadError:
            state.postLoadError = nil

        case .mapDidMove(let coordinate):
            state.mapCenterCoordinate = coordinate
            // 초기 로딩 완료 후 지도가 이동한 경우에만 검색 버튼 표시
            if state.hasLoadedInitialPosts {
                state.showSearchButton = true
            }

        case .searchInCurrentMap:
            guard let center = state.mapCenterCoordinate else { return }
            state.showSearchButton = false
            // span 기반으로 maxDistance 계산 (latitudeDelta * 111km ≈ 위도 1도 거리)
            let maxDistance = state.currentSpan.latitudeDelta * 111000 / 2
            send(.fetchPostsByLocation(
                longitude: center.longitude,
                latitude: center.latitude,
                maxDistance: maxDistance
            ))
        }
    }

    private func fetchPostsByLocation(longitude: Double, latitude: Double, maxDistance: Double) async {
        state.isLoadingPosts = true
        state.postLoadError = nil

        do {
            let response = try await PostAPI.shared.getPostsByGeolocation(
                category: ["sell"],
                longitude: longitude,
                latitude: latitude,
                maxDistance: maxDistance
            )

            let posts = response.data.compactMap { postResponse -> PostAnnotation? in
                guard let geolocation = postResponse.geolocation else { return nil }

                // 현재 사용자가 좋아요 했는지 확인
                let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? ""
                let isLiked = postResponse.likes.contains(currentUserId)

                return PostAnnotation(
                    id: postResponse.postId,
                    title: postResponse.title,
                    media: postResponse.files.first ?? "",
                    like: isLiked,
                    profileImage: postResponse.creator.profileImage ?? "",
                    nickname: postResponse.creator.nick,
                    latitude: geolocation.latitude,
                    longitude: geolocation.longitude,
                    price: postResponse.price ?? 0
                )
            }

            state.posts = posts
            state.isLoadingPosts = false
            state.hasLoadedInitialPosts = true

            print("위치 기반 게시글 조회 성공: \(posts.count)개")
//            print(TokenManager.shared.accessToken)

        } catch {
            state.isLoadingPosts = false
            state.postLoadError = error.localizedDescription
            print("위치 기반 게시글 조회 실패: \(error.localizedDescription)")
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

                // 위치 기반 게시글 조회 (5km 반경)
                print("현재 위치: \(coordinate.latitude), \(coordinate.longitude)")
                send(.fetchPostsByLocation(
                    longitude: coordinate.longitude,
                    latitude: coordinate.latitude,
                    maxDistance: 5000
                ))
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
