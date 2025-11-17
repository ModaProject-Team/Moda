//
//  MockPostData.swift
//  Moda
//
//  Created by Suji Jang on 11/17/25.
//

import Foundation

extension PostAnnotation {
    static let mockData: [PostAnnotation] = [
        PostAnnotation(
            id: "1",
            title: "빈티지 청자켓",
            media: "jacket1",
            like: true,
            profileImage: "profile1",
            nickname: "패션왕",
            latitude: 37.5665,
            longitude: 126.9780,
            price: 45000
        ),
        PostAnnotation(
            id: "2",
            title: "나이키 에어포스",
            media: "shoes1",
            like: false,
            profileImage: "profile2",
            nickname: "슈즈러버",
            latitude: 37.5670,
            longitude: 126.9790,
            price: 89000
        ),
        PostAnnotation(
            id: "3",
            title: "겨울 롱패딩",
            media: "padding1",
            like: true,
            profileImage: "profile3",
            nickname: "따뜻이",
            latitude: 37.5660,
            longitude: 126.9770,
            price: 120000
        ),
        PostAnnotation(
            id: "4",
            title: "데님 팬츠",
            media: "jeans1",
            like: false,
            profileImage: "profile4",
            nickname: "데님매니아",
            latitude: 37.5675,
            longitude: 126.9785,
            price: 35000
        ),
        PostAnnotation(
            id: "5",
            title: "가죽 숄더백",
            media: "bag1",
            like: true,
            profileImage: "profile5",
            nickname: "백러버",
            latitude: 37.5655,
            longitude: 126.9775,
            price: 67000
        ),
        PostAnnotation(
            id: "6",
            title: "오버핏 후드티",
            media: "hoodie1",
            like: false,
            profileImage: "profile6",
            nickname: "스트릿패션",
            latitude: 37.5680,
            longitude: 126.9795,
            price: 28000
        ),
        PostAnnotation(
            id: "7",
            title: "골프 바람막이",
            media: "windbreaker1",
            like: true,
            profileImage: "profile7",
            nickname: "골프조아",
            latitude: 37.5650,
            longitude: 126.9765,
            price: 95000
        ),
        PostAnnotation(
            id: "8",
            title: "뉴발란스 530",
            media: "nb530",
            like: false,
            profileImage: "profile8",
            nickname: "운동화덕후",
            latitude: 37.5685,
            longitude: 126.9800,
            price: 79000
        )
    ]
}
