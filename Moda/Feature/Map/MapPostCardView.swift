//
//  MapPostCardView.swift
//  Moda
//
//  Created by Suji Jang on 11/17/25.
//

import SwiftUI

struct MapPostCardView: View {
    let post: PostAnnotation

    var body: some View {
        HStack(spacing: 12) {
            Image(post.media)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(post.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.gray1)
                    .lineLimit(1)

                Text("\(post.price.formatted())원")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue1)

                HStack(spacing: 4) {
                    Image(post.profileImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 16, height: 16)
                        .clipShape(Circle())

                    Text(post.nickname)
                        .font(.system(size: 12))
                        .foregroundColor(.gray2)
                }
            }

            Spacer()

            Button(action: {}) {
                Image(systemName: post.like ? "heart.fill" : "heart")
                    .foregroundColor(post.like ? .pink1 : .gray3)
                    .font(.system(size: 20))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: -2)
        .padding(.horizontal, 16)
        .padding(.bottom, 60)
    }
}
