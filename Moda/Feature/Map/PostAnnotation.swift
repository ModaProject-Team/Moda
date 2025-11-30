//
//  PostAnnotation.swift
//  Moda
//
//  Created by Suji Jang on 11/17/25.
//

import Foundation
import CoreLocation

struct PostAnnotation: Identifiable {
    let id: String
    let title: String
    let media: String  // 대표 이미지 URL
    var like: Bool  // 좋아요 여부
    let profileImage: String  // 작성자 프로필 이미지
    let nickname: String  // 작성자 닉네임
    let latitude: Double  // 위도
    let longitude: Double  // 경도
    let price: Int  // 가격
    let creatorId: String  // 작성자 ID

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
