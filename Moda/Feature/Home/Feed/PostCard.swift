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
            likeCount: likes.count
        )

        if let currentUserId = currentUserId {
            postCard.isLiked = likes.contains(currentUserId)
        }

        return postCard
    }
}

extension PostCard {
    static var mockData: [PostCard] {
        let calendar = Calendar.current
        let now = Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let today = formatter.string(from: now)
        let twoDaysAgo = formatter.string(from: calendar.date(byAdding: .day, value: -2, to: now)!)
        let threeDaysAgo = formatter.string(from: calendar.date(byAdding: .day, value: -3, to: now)!)
        let fiveDaysAgo = formatter.string(from: calendar.date(byAdding: .day, value: -5, to: now)!)
        let oneWeekAgo = formatter.string(from: calendar.date(byAdding: .day, value: -7, to: now)!)
        let twoWeeksAgo = formatter.string(from: calendar.date(byAdding: .day, value: -14, to: now)!)

        return [
            PostCard(
                id: "1",
                category: "study",
                title: "같이 앱 만드실 분 구해요",
                price: 0,
                createdAt: today,
                creator: Creator(
                    userId: "user1",
                    nickname: "수지",
                    profileImage: nil
                ),
                imageURL: nil,
                likes: ["user2", "user3"],
                buyers: [],
                latitude: 37.517682,
                longitude: 126.886417,
                locationName: "문래역 1번 출구",
                likeCount: 2
            ),
            PostCard(
                id: "2",
                category: "electronics",
                title: "애플 충전기 팔아요",
                price: 15000,
                createdAt: twoDaysAgo,
                creator: Creator(
                    userId: "user2",
                    nickname: "민준",
                    profileImage: nil
                ),
                imageURL: nil,
                likes: ["user1", "user3", "user4"],
                buyers: [],
                latitude: 37.517682,
                longitude: 126.886417,
                locationName: "강남역 2번 출구",
                isLiked: true,
                likeCount: 3
            ),
            PostCard(
                id: "3",
                category: "fashion",
                title: "나이키 후드티 거의 새거",
                price: 35000,
                createdAt: threeDaysAgo,
                creator: Creator(
                    userId: "user3",
                    nickname: "서연",
                    profileImage: nil
                ),
                imageURL: nil,
                likes: ["user2", "user5"],
                buyers: [],
                latitude: 37.517682,
                longitude: 126.886417,
                locationName: nil,
                likeCount: 2
            ),
            PostCard(
                id: "4",
                category: "books",
                title: "Swift 책 필요하신 분",
                price: 25000,
                createdAt: fiveDaysAgo,
                creator: Creator(
                    userId: "user4",
                    nickname: "지호",
                    profileImage: nil
                ),
                imageURL: nil,
                likes: ["user1"],
                buyers: [],
                latitude: 37.517682,
                longitude: 126.886417,
                locationName: "신촌역 앞",
                likeCount: 1
            ),
            PostCard(
                id: "5",
                category: "living",
                title: "키보드 팔아요 상태좋음",
                price: 45000,
                createdAt: oneWeekAgo,
                creator: Creator(
                    userId: "user5",
                    nickname: "하은",
                    profileImage: nil
                ),
                imageURL: nil,
                likes: ["user1", "user2", "user3", "user4", "user5"],
                buyers: [],
                latitude: 37.517682,
                longitude: 126.886417,
                locationName: "홍대입구역",
                isLiked: true,
                likeCount: 5
            ),
            PostCard(
                id: "6",
                category: "sports",
                title: "요가 매트 나눔해요",
                price: 0,
                createdAt: twoWeeksAgo,
                creator: Creator(
                    userId: "user6",
                    nickname: "준서",
                    profileImage: nil
                ),
                imageURL: nil,
                likes: ["user2", "user3", "user6"],
                buyers: [],
                latitude: 37.517682,
                longitude: 126.886417,
                locationName: "여의도역 3번 출구",
                likeCount: 3
            )
        ]
    }
}
