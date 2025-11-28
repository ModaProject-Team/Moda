//
//  SearchBarView.swift
//  Moda
//
//  Created by 금가경 on 11/28/25.
//

import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    let placeholder: String
    var onClear: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .foregroundColor(.gray1)

            if !text.isEmpty {
                Button {
                    onClear?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.gray2)
                }
            }

            Image(systemName: "magnifyingglass")
                .font(.system(size: 18))
                .foregroundColor(.gray2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(Color.gray5)
        )
    }
}
