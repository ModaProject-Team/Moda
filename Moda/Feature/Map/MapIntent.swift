//
//  MapIntent.swift
//  Moda
//
//  Created by Suji Jang on 11/15/25.
//

import SwiftUI
import MapKit

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
}
