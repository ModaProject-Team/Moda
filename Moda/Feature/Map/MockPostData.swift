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
            title: "빈백 소파 판매해요",
            media: "beanbag",
            like: true,
            profileImage: "cat",
            nickname: "패션왕",
            latitude: 37.5180,
            longitude: 126.8950,
            price: 45000
        ),
        PostAnnotation(
            id: "2",
            title: "맥북 상태 좋아요",
            media: "mac",
            like: false,
            profileImage: "dog",
            nickname: "슈즈러버",
            latitude: 37.5185,
            longitude: 126.8945,
            price: 89000
        ),
        PostAnnotation(
            id: "3",
            title: "편안한 빈백 드립니다",
            media: "beanbag",
            like: true,
            profileImage: "cat",
            nickname: "따뜻이",
            latitude: 37.5178,
            longitude: 126.8948,
            price: 120000
        ),
        PostAnnotation(
            id: "4",
            title: "맥북 팝니다",
            media: "mac",
            like: false,
            profileImage: "dog",
            nickname: "데님매니아",
            latitude: 37.5182,
            longitude: 126.8953,
            price: 35000
        ),
        PostAnnotation(
            id: "5",
            title: "빈백 소파 급처",
            media: "beanbag",
            like: true,
            profileImage: "cat",
            nickname: "백러버",
            latitude: 37.5175,
            longitude: 126.8946,
            price: 67000
        ),
        PostAnnotation(
            id: "6",
            title: "맥북 에어 2020",
            media: "mac",
            like: false,
            profileImage: "dog",
            nickname: "스트릿패션",
            latitude: 37.5187,
            longitude: 126.8955,
            price: 28000
        ),
        PostAnnotation(
            id: "7",
            title: "빈백 소파 팝니다",
            media: "beanbag",
            like: true,
            profileImage: "cat",
            nickname: "골프조아",
            latitude: 37.5172,
            longitude: 126.8944,
            price: 95000
        ),
        PostAnnotation(
            id: "8",
            title: "맥북 프로 M1",
            media: "mac",
            like: false,
            profileImage: "dog",
            nickname: "운동화덕후",
            latitude: 37.5189,
            longitude: 126.8958,
            price: 79000
        ),
        // 강남역 근처 (클러스터링 테스트용)
        PostAnnotation(
            id: "9",
            title: "아이폰 15 Pro",
            media: "mac",
            like: false,
            profileImage: "dog",
            nickname: "테크마니아",
            latitude: 37.4980,
            longitude: 127.0276,
            price: 650000
        ),
        PostAnnotation(
            id: "10",
            title: "에어팟 프로 2",
            media: "beanbag",
            like: true,
            profileImage: "cat",
            nickname: "음악러버",
            latitude: 37.4982,
            longitude: 127.0278,
            price: 180000
        ),
        PostAnnotation(
            id: "11",
            title: "애플워치 울트라",
            media: "mac",
            like: false,
            profileImage: "dog",
            nickname: "운동왕",
            latitude: 37.4984,
            longitude: 127.0280,
            price: 320000
        ),
        PostAnnotation(
            id: "12",
            title: "맥북 에어 M2",
            media: "mac",
            like: true,
            profileImage: "cat",
            nickname: "개발자",
            latitude: 37.4978,
            longitude: 127.0274,
            price: 890000
        )
    ]
}
