//
//  ClusterAnnotationView.swift
//  Moda
//
//  Created by Suji Jang on 11/18/25.
//

import SwiftUI

struct ClusterAnnotationView: View {
    let count: Int
    let representativeImage: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.blue1 : Color.white)
                    .frame(width: 58, height: 58)

                if !representativeImage.isEmpty {
                    MediaImageView(
                        mediaURL: representativeImage,
                        contentMode: .fill,
                        placeholder: {
                            AnyView(
                                Circle()
                                    .fill(Color.blue1.opacity(0.3))
                            )
                        }
                    )
                    .frame(width: 47, height: 47)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.blue1.opacity(0.3))
                        .frame(width: 47, height: 47)
                }

                Circle()
                    .fill(Color.blue1.opacity(0.3))
                    .frame(width: 47, height: 47)

                Text("\(count)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
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

#Preview {
    ClusterAnnotationView(count: 5, representativeImage: "mac", isSelected: false)
}
