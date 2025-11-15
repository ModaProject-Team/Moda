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

    /// 앱이 처음 로드될 때 초기 위치 설정
    case loadInitialLocation
}
