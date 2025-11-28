//
//  TransactionsView.swift
//  Moda
//
//  Created by Suji Jang on 11/27/25.
//

import SwiftUI
import Kingfisher

struct TransactionsView: View {
    @EnvironmentObject var navigator: AppNavigator
    @State private var store = TransactionsStore()

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            if store.state.isLoading && store.state.transactions.isEmpty {
                shimmerList
            } else if store.state.transactions.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(store.state.transactions.enumerated()), id: \.element.id) { index, transaction in
                            TransactionItemView(
                                transaction: transaction,
                                onTapped: { navigator.push(.productDetail(postId: transaction.postId)) }
                            )
                            .onAppear {
                                if index >= store.state.transactions.count - 4 {
                                    store.send(.loadMore)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
                .refreshable {
                    store.send(.refresh)
                }
            }
        }
        .navigationTitle("거래 내역")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    navigator.pop()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18))
                        .foregroundColor(.gray1)
                }
            }
        }
        .task {
            store.send(.onAppear)
        }
    }

    private var shimmerList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { _ in
                    TransactionShimmerView()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(.gray3)

            Text("거래 내역이 없습니다")
                .H2()
                .foregroundColor(.gray2)

            Text("결제를 완료한 상품이 없습니다")
                .Body2()
                .foregroundColor(.gray3)
        }
    }
}

private struct TransactionItemView: View {
    let transaction: Transaction
    let onTapped: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if let thumbnailURL = transaction.thumbnailURL, let url = URL(string: thumbnailURL) {
                KFImage(url)
                    .requestModifier(KFHeaders.modifier)
                    .placeholder {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.gray5)
                    }
                    .cacheOriginalImage()
                    .fade(duration: 0.2)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.gray5)
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(.gray3)
                    }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(transaction.productName)
                    .Body1()
                    .foregroundColor(.gray1)
                    .lineLimit(2)

                Text(transaction.formattedPrice)
                    .H2()
                    .foregroundColor(.gray1)

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green1)

                    Text(transaction.formattedDate)
                        .Body2()
                        .foregroundColor(.gray2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.gray3)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.gray4, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTapped()
        }
    }
}

private struct TransactionShimmerView: View {
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.gray4)
                .frame(width: 80, height: 80)
                .shimmer()

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray4)
                    .frame(height: 16)
                    .shimmer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray4)
                    .frame(width: 100, height: 20)
                    .shimmer()

                Spacer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray4)
                    .frame(width: 120, height: 12)
                    .shimmer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Circle()
                .fill(Color.gray4)
                .frame(width: 20, height: 20)
                .shimmer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.gray4, lineWidth: 1)
        )
    }
}

#Preview {
    TransactionsView()
        .environmentObject(AppNavigator.shared)
}
