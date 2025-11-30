//
//  DateFormatter+Extension.swift
//  Moda
//
//  Created by 금가경 on 11/28/25.
//

import Foundation

extension String {
    /// ISO8601 날짜 문자열을 상대 시간으로 변환 (방금 전, X분 전, X시간 전 등)
    func toRelativeTimeString() -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var parsedDate: Date?

        if let date = isoFormatter.date(from: self) {
            parsedDate = date
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            parsedDate = dateFormatter.date(from: self)
        }

        guard let date = parsedDate else {
            return self
        }

        let now = Date()
        let interval = now.timeIntervalSince(date)

        if interval < 60 {
            return "방금 전"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)분 전"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)시간 전"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)일 전"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd"
            return formatter.string(from: date)
        }
    }
}
