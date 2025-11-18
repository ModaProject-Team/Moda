//
//  MapItem.swift
//  Moda
//
//  Created by Suji Jang on 11/18/25.
//

import Foundation
import CoreLocation

// 지도에 표시될 아이템 (개별 핀 또는 클러스터)
enum MapItem: Identifiable {
    case single(PostAnnotation)
    case cluster([PostAnnotation])

    var id: String {
        switch self {
        case .single(let post):
            return post.id
        case .cluster(let posts):
            // 클러스터 ID는 포함된 게시물 ID들의 조합
            return "cluster-\(posts.map { $0.id }.sorted().joined())"
        }
    }

    // 지도상 좌표 (클러스터는 중심점)
    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .single(let post):
            return post.coordinate
        case .cluster(let posts):
            let avgLat = posts.map { $0.latitude }.reduce(0, +) / Double(posts.count)
            let avgLon = posts.map { $0.longitude }.reduce(0, +) / Double(posts.count)
            return CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon)  // 포함된 게시물들의 좌표 평균값으로 중심점 계산
        }
    }

    // 포함된 게시물들
    var posts: [PostAnnotation] {
        switch self {
        case .single(let post):
            return [post]  // 항상 배열 형태로 접근 가능하게 설계
        case .cluster(let posts):
            return posts  // 원래 배열 그대로
        }
    }

    // 게시물 개수
    var count: Int {
        posts.count
    }

    // 대표 게시물 (첫 번째)
    var representativePost: PostAnnotation? {
        posts.first
    }
}
