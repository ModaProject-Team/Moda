//
//  PlayButton.swift
//  Moda
//
//  Created by 금가경 on 11/28/25.
//

import SwiftUI

/// 통일된 스타일의 비디오 재생 버튼
struct PlayButton: View {
    let action: () -> Void
    var size: CGFloat = 50
    var iconSize: CGFloat = 20
    var backgroundColor: Color = .white.opacity(0.9)
    var iconColor: Color = .black

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: size, height: size)

                Image(systemName: "play.fill")
                    .font(.system(size: iconSize))
                    .foregroundColor(iconColor)
                    .offset(x: 2)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        PlayButton(action: {})
    }
}
