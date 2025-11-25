//
//  PaymentValidationResponse.swift
//  Moda
//
//  Created by Suji Jang on 11/25/24.
//

import Foundation

/// 결제 검증 응답 모델
struct PaymentValidationResponse: Decodable {
    let buyerId: String
    let postId: String
    let merchantUid: String
    let productName: String
    let price: Int
    let paidAt: String

    enum CodingKeys: String, CodingKey {
        case buyerId = "buyer_id"
        case postId = "post_id"
        case merchantUid = "merchant_uid"
        case productName = "productName"
        case price
        case paidAt = "paidAt"
    }
}
