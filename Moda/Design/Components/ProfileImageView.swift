//
//  ProfileImageView.swift
//  Moda
//
//  Created by 금가경 on 11/28/25.
//

import SwiftUI

struct ProfileImageView: View {
    let imageURL: URL?
    let size: CGFloat

    var body: some View {
        Group {
            if let url = imageURL {
                CachedImageView(
                    url: url,
                    targetSize: CGSize(width: size, height: size),
                    contentMode: .fill,
                    placeholder: {
                        AnyView(placeholder)
                    }
                )
                .cacheOriginalImage()
                .fade(duration: 0.2)
                .cancelOnDisappear(true)
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                placeholder
            }
        }
    }

    private var placeholder: some View {
        ZStack {
            Circle()
                .fill(Color.gray3)

            Image(systemName: "person.fill")
                .font(.system(size: iconSize))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }

    private var iconSize: CGFloat {
        size * 0.42
    }
}
