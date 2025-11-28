//
//  TransactionsState.swift
//  Moda
//
//  Created by Suji Jang on 11/27/25.
//

import Foundation

struct TransactionsState {
    var transactions: [Transaction] = []
    var nextCursor: String = ""
    var hasMore: Bool = true

    var isLoading: Bool = false
    var errorMessage: String? = nil
}

struct Transaction: Identifiable {
    let id: String
    let productName: String
    let price: Int
    let paidAt: String
    let postId: String
    let merchantUid: String
    let thumbnailURL: String?

    var formattedPrice: String {
        "\(price.formatted())원"
    }

    var formattedDate: String {
        // ISO 8601 날짜 포맷 파싱
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = isoFormatter.date(from: paidAt) else {
            return paidAt
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")

        return formatter.string(from: date)
    }
}
