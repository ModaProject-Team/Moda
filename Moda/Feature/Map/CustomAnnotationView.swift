//
//  CustomAnnotationView.swift
//  Moda
//
//  Created by Suji Jang on 11/17/25.
//

import SwiftUI
import Kingfisher

struct CustomAnnotationView: View {
    let post: PostAnnotation
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {

            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 17)
                        .frame(width: 54, height: 54)
                }

                RoundedRectangle(cornerRadius: 17)
                    .fill(isSelected ? Color.blue1 : Color.white)
                    .frame(width: 54, height: 54)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)

                MediaImageView(
                    mediaURL: post.media,
                    contentMode: .fill,
                    placeholder: {
                        AnyView(
                            Image(systemName: "photo")
                                .foregroundColor(.gray3)
                        )
                    }
                )
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 13))
            }
            .scaleEffect(isSelected ? 1.2 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)

            Triangle()
                .fill(isSelected ? Color.blue1.opacity(0.1) : Color.white)
                .frame(width: 16, height: 8)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                .offset(y: -1)
                .scaleEffect(isSelected ? 1.2 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
