//
//  TabHeaderView.swift
//  Moda
//
//  Created by 금가경 on 11/25/25.
//

import SwiftUI

struct TabHeaderView: View {
    let title: String
    var actions: [HeaderAction] = []

    var body: some View {
        HStack(spacing: 20) {
            Text(title)
                .H1()
                .foregroundColor(.gray1)

            Spacer()

            ForEach(actions) { action in
                Button(action: action.action) {
                    Image(systemName: action.icon)
                        .font(.system(size: 18))
                        .foregroundColor(.gray1)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct HeaderAction: Identifiable {
    let id = UUID()
    let icon: String
    let action: () -> Void
}
