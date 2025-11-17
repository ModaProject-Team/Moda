//
//  CustomAnnotationView.swift
//  Moda
//
//  Created by Suji Jang on 11/17/25.
//

import SwiftUI

struct CustomAnnotationView: View {
    let post: PostAnnotation

    var body: some View {
        VStack(spacing: 0) {
            
            ZStack {
                RoundedRectangle(cornerRadius: 17)
                    .fill(Color.white)
                    .frame(width: 54, height: 54)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)

                Image(post.media)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 13))
            }

            Triangle()
                .fill(Color.white)
                .frame(width: 16, height: 8)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                .offset(y: -1)
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
