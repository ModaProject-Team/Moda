//
//  PaymentListResponse.swift
//  Moda
//
//  Created by Suji Jang on 11/27/25.
//

import Foundation

/// 거래 내역 모델
struct PaymentTransaction: Decodable, Identifiable {
    let id: String // buyerId_postId_merchantUid로 구성
    let buyerId: String
    let postId: String
    let merchantUid: String
    let productName: String
    let price: Int
    let paidAt: String
    let post: PostSummary?

    enum CodingKeys: String, CodingKey {
        case buyerId = "buyer_id"
        case postId = "post_id"
        case merchantUid = "merchant_uid"
        case productName
        case price
        case paidAt
        case post
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        buyerId = try container.decode(String.self, forKey: .buyerId)
        postId = try container.decode(String.self, forKey: .postId)
        merchantUid = try container.decode(String.self, forKey: .merchantUid)
        productName = try container.decode(String.self, forKey: .productName)
        price = try container.decode(Int.self, forKey: .price)
        paidAt = try container.decode(String.self, forKey: .paidAt)
        post = try? container.decode(PostSummary.self, forKey: .post)

        // ID 생성
        id = "\(buyerId)_\(postId)_\(merchantUid)"
    }
}

/// 게시글 요약 정보
struct PostSummary: Decodable {
    let title: String
    let files: [String]
    let creator: PostCreator
}

/// 거래 내역 리스트 응답
struct PaymentListResponse: Decodable {
    let data: [PaymentTransaction]
    let nextCursor: String

    enum CodingKeys: String, CodingKey {
        case data
        case nextCursor = "next_cursor"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        data = try container.decode([PaymentTransaction].self, forKey: .data)
        nextCursor = try container.decodeIfPresent(String.self, forKey: .nextCursor) ?? "0"
    }
}
