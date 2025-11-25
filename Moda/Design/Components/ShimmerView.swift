//
//  ShimmerView.swift
//  Moda
//
//  Created by 금가경 on 11/25/24.
//

import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.white.opacity(0.6),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .black, location: 0),
                                    .init(color: .clear, location: 0.5),
                                    .init(color: .black, location: 1)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .rotationEffect(.degrees(70))
                        .offset(x: phase)
                )
            )
            .onAppear {
                withAnimation(
                    Animation
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 1000
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

struct PostCardShimmerView: View {
    let itemWidth: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.gray5)
                .frame(width: itemWidth, height: itemWidth)
                .shimmer()

            HStack(spacing: 8) {
                Circle()
                    .fill(Color.gray5)
                    .frame(width: 24, height: 24)
                    .shimmer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray5)
                    .frame(width: 60, height: 12)
                    .shimmer()

                Spacer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray5)
                    .frame(width: 40, height: 12)
                    .shimmer()
            }
            .padding(.top, 8)
            .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray5)
                    .frame(height: 14)
                    .shimmer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray5)
                    .frame(width: itemWidth * 0.7, height: 14)
                    .shimmer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray5)
                    .frame(width: itemWidth * 0.5, height: 12)
                    .shimmer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray5)
                    .frame(width: 80, height: 16)
                    .shimmer()
            }
            .padding(.top, 6)
            .padding(.bottom, 8)
        }
        .frame(width: itemWidth, alignment: .leading)
    }
}
