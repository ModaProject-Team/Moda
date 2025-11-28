//
//  MapIntent.swift
//  Moda
//
//  Created by Suji Jang on 11/15/25.
//

import SwiftUI
import MapKit
import CoreLocation

enum MapIntent {
    /// 사용자가 지도 위치를 스크롤하거나 제스처로 변경할 때 발생
    case updateCameraPosition(MapCameraPosition)

    /// 특정 좌표로 카메라를 이동 (예: 현재 위치로 이동)
    case moveToLocation(CLLocationCoordinate2D)

    /// LocationManager 초기화 (델리게이트 콜백 트리거)
    case setupLocationManager

    /// 앱 위치 권한 요청
    case requestLocationPermission

    /// 앱 설정 화면으로 이동
    case openAppSettings

    /// 권한 거부 Alert 닫기
    case dismissPermissionDeniedAlert

    /// 위치 서비스 비활성화 Alert 닫기
    case dismissLocationServiceDisabledAlert

    /// 위치 업데이트 실패 Alert 닫기
    case dismissLocationUpdateFailedAlert

    /// 위치 업데이트 재시도
    case retryLocationUpdate

    /// 사용자의 현재 위치로 카메라 이동
    case moveToUserLocation

    /// 게시물 선택
    case selectPost(String?)

    /// 지도 확대/축소 레벨 업데이트
    case updateSpan(MKCoordinateSpan)

    /// 게시물 인덱스로 선택
    case selectPostByIndex(Int?)

    /// 클러스터 선택
    case selectCluster(Set<String>?)

    /// 클러스터 시트 표시
    case showClusterSheet([PostAnnotation])

    /// 클러스터 시트 닫기
    case dismissClusterSheet

    /// 위치 기반 게시글 조회
    case fetchPostsByLocation(longitude: Double, latitude: Double, maxDistance: Double)

    /// 게시글 로딩 에러 알림 닫기
    case dismissPostLoadError

    /// 지도 이동 시 중심 좌표 업데이트 및 검색 버튼 표시
    case mapDidMove(CLLocationCoordinate2D)

    /// 현 지도에서 검색 버튼 탭
    case searchInCurrentMap

    /// 좋아요 토글
    case toggleLike(postId: String, isLiked: Bool)

    /// 외부에서 좋아요 상태 업데이트
    case updateLikeFromExternal(postId: String, isLiked: Bool)

    /// 지도 새로고침 (게시물 삭제/수정 시)
    case refresh
}
