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
                Circle()
                    .fill(isSelected ? Color.blue1 : Color.white)
                    .frame(width: 58, height: 58)

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
                .frame(width: 47, height: 47)
                .clipShape(Circle())
            }
            .scaleEffect(isSelected ? 1.2 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)

            Triangle()
                .fill(isSelected ? Color.blue1.opacity(0.1) : Color.white)
                .frame(width: 16, height: 8)
                .offset(y: -1)
                .scaleEffect(isSelected ? 1.2 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
    }
}
