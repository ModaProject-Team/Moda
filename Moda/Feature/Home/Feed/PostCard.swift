//
//  PostCard.swift
//  Moda
//
//  Created by 금가경 on 11/16/25.
//

import Foundation

struct PostCard: Identifiable {
    let id: String
    let category: String
    let title: String
    let price: Int?
    let createdAt: String
    let creator: Creator
    let imageURL: String?
    let likes: [String]
    let buyers: [String]
    let latitude: Double?
    let longitude: Double?
    let locationName: String?
    let commentCount: Int

    struct Creator {
        let userId: String
        let nickname: String
        let profileImage: String?
    }

    var isLiked: Bool = false
    var likeCount: Int

    var formattedPrice: String {
        guard let price = price else { return "나눔" }
        if price == 0 {
            return "나눔"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formattedNumber = formatter.string(from: NSNumber(value: price)) ?? "\(price)"
        return "\(formattedNumber)원"
    }

    var isVideo: Bool {
        guard let imageURL = imageURL else { return false }
        let videoExtensions = ["mp4", "mov", "m4v", "avi", "mkv"]
        let fileExtension = (imageURL as NSString).pathExtension.lowercased()
        return videoExtensions.contains(fileExtension)
    }

    var formattedDate: String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var parsedDate: Date?

        if let date = isoFormatter.date(from: createdAt) {
            parsedDate = date
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            parsedDate = dateFormatter.date(from: createdAt)
        }

        guard let date = parsedDate else {
            return createdAt
        }

        let now = Date()
        let interval = now.timeIntervalSince(date)

        if interval < 60 {
            return "방금 전"
        }
        else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)분 전"
        }
        else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)시간 전"
        }
        else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)일 전"
        }
        else {
            let outputFormatter = DateFormatter()
            outputFormatter.locale = Locale(identifier: "ko_KR")
            outputFormatter.dateFormat = "MM.dd"
            return outputFormatter.string(from: date)
        }
    }

    var formattedLocation: String? {
        if let name = locationName, !name.isEmpty {
            return name
        }
        return nil
    }

    // 게시글의 좌표와 현재 사용자의 위치를 이용해 구면 거리 계산
    func formattedDistance(from currentLocation: (latitude: Double, longitude: Double)? = nil) -> String? {

        // 장소명이 없으면 거리도 표시하지 않음
        guard let locationName = locationName, !locationName.isEmpty else {
            return nil
        }

        // 현재 위치 또는 게시글 위치가 없을 경우 nil 반환
        guard let latitude = latitude,
              let longitude = longitude,
              let current = currentLocation else {
            return nil
        }

        // 지구 반지름 (미터 단위)
        let earthRadius = 6371000.0

        // 위도·경도를 라디안(radian)으로 변환
        let lat1Rad = current.latitude * .pi / 180
        let lat2Rad = latitude * .pi / 180
        let deltaLat = (latitude - current.latitude) * .pi / 180
        let deltaLon = (longitude - current.longitude) * .pi / 180

        // 하버사인 공식(Haversine Formula)
        // 두 위경도 좌표 간 구면 거리 계산에 사용되는 공식
        let a = sin(deltaLat / 2) * sin(deltaLat / 2) +
                cos(lat1Rad) * cos(lat2Rad) *
                sin(deltaLon / 2) * sin(deltaLon / 2)

        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        // 최종 거리 (미터)
        let distance = earthRadius * c

        if distance < 1000 {
            return String(format: "%.0fm", distance)
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
}

extension Post {
    func toPostCard(currentUserId: String? = nil) -> PostCard {
        var postCard = PostCard(
            id: postId,
            category: category,
            title: title,
            price: price,
            createdAt: createdAt,
            creator: PostCard.Creator(
                userId: creator.userId,
                nickname: creator.nickname,
                profileImage: creator.profileImage
            ),
            imageURL: files.first,
            likes: likes,
            buyers: buyers,
            latitude: geolocation?.latitude,
            longitude: geolocation?.longitude,
            locationName: value1,
            commentCount: commentCount ?? 0,
            likeCount: likes.count
        )

        if let currentUserId = currentUserId {
            postCard.isLiked = likes.contains(currentUserId)
        }

        return postCard
    }
}
