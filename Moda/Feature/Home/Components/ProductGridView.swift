//
//  ProductGridView.swift
//  Moda
//
//  Created by 금가경 on 11/25/24.
//

import SwiftUI
import CoreLocation

struct ProductGridView: View {
    let products: [PostCard]
    let itemWidth: CGFloat
    let spacing: CGFloat
    let horizontalPadding: CGFloat
    let currentLocation: CLLocationCoordinate2D?
    let isLoading: Bool
    let emptyMessage: String
    let onLikeTapped: (String) -> Void
    let onProductTapped: ((String) -> Void)?
    let onLoadMore: (() -> Void)?

    var body: some View {
        if products.isEmpty && isLoading {
            shimmerGrid
        } else if products.isEmpty {
            Text(emptyMessage)
                .Body1()
                .foregroundColor(.gray2)
                .frame(maxWidth: .infinity)
                .padding(.top, 50)
        } else {
            HStack(alignment: .top, spacing: spacing) {
                leftColumn
                rightColumn
            }
            .padding(.horizontal, horizontalPadding)
            .animation(.none, value: products.count)
        }
    }

    private var shimmerGrid: some View {
        HStack(alignment: .top, spacing: spacing) {
            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    PostCardShimmerView(itemWidth: itemWidth)
                }
            }
            .frame(width: itemWidth)

            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    PostCardShimmerView(itemWidth: itemWidth)
                }
            }
            .frame(width: itemWidth)
        }
        .padding(.horizontal, horizontalPadding)
    }

    private var leftColumn: some View {
        VStack(spacing: 12) {
            ForEach(Array(products.enumerated().filter { $0.offset % 2 == 0 }), id: \.element.id) { index, product in
                PostCardView(
                    product: product,
                    itemWidth: itemWidth,
                    currentLocation: currentLocation,
                    onLikeTapped: { onLikeTapped(product.id) },
                    onTapped: { onProductTapped?(product.id) }
                )
                .onAppear {
                    if index >= products.count - 4 {
                        onLoadMore?()
                    }
                }
            }
        }
        .frame(width: itemWidth)
    }

    private var rightColumn: some View {
        VStack(spacing: 12) {
            ForEach(Array(products.enumerated().filter { $0.offset % 2 == 1 }), id: \.element.id) { index, product in
                PostCardView(
                    product: product,
                    itemWidth: itemWidth,
                    currentLocation: currentLocation,
                    onLikeTapped: { onLikeTapped(product.id) },
                    onTapped: { onProductTapped?(product.id) }
                )
                .onAppear {
                    if index >= products.count - 4 {
                        onLoadMore?()
                    }
                }
            }
        }
        .frame(width: itemWidth)
    }
}
