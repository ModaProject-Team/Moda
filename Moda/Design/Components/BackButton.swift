//
//  BackButton.swift
//  Moda
//
//  Created by 금가경 on 11/28/25.
//

import SwiftUI

/// 통일된 스타일의 뒤로가기 버튼
struct BackButton: View {
    let action: () -> Void
    var tintColor: Color = .gray1

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16))
                .foregroundColor(tintColor)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
    }
}

#Preview {
    ZStack {
        Color.white
        BackButton(action: {})
    }
}
