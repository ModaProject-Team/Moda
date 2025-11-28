//
//  ProfileImageView.swift
//  Moda
//
//  Created by 금가경 on 11/28/25.
//

import SwiftUI
import Kingfisher

struct ProfileImageView: View {
    let imageURL: URL?
    let size: CGFloat

    var body: some View {
        Group {
            if let url = imageURL {
                KFImage(url)
                    .requestModifier(KFHeaders.modifier)
                    .placeholder {
                        placeholder
                    }
                    .cacheOriginalImage()
                    .fade(duration: 0.2)
                    .cancelOnDisappear(true)
                    .resizable()
                    .scaledToFill()
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
