//
//  EmptyStateView.swift
//  Moda
//
//  Created by 금가경 on 11/28/25.
//

import SwiftUI

struct EmptyStateView: View {
    let message: String
    let subtitle: String?

    init(message: String, subtitle: String? = nil) {
        self.message = message
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(spacing: 12) {
            Spacer()

            Text(message)
                .Body1()
                .foregroundColor(.gray2)

            if let subtitle = subtitle {
                Text(subtitle)
                    .Body2()
                    .foregroundColor(.gray3)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
