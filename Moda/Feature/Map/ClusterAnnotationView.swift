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
        ZStack {
            Circle()
                .fill(isSelected ? Color.blue1 : Color.white)
                .frame(width: 58, height: 58)

            if !representativeImage.isEmpty {
                Image(representativeImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
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
    }
}

#Preview {
    ClusterAnnotationView(count: 5, representativeImage: "mac", isSelected: false)
}
