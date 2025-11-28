//
//  TransactionsStore.swift
//  Moda
//
//  Created by Suji Jang on 11/27/25.
//

import SwiftUI

@MainActor
@Observable
final class TransactionsStore {
    var state = TransactionsState()

    private let postAPI: PostAPIProtocol

    init(postAPI: PostAPIProtocol = PostAPI.shared) {
        self.postAPI = postAPI
    }

    func send(_ intent: TransactionsIntent) {
        switch intent {
        case .onAppear:
            if state.transactions.isEmpty {
                loadTransactions(refresh: true)
            }

        case .loadMore:
            guard !state.isLoading, state.hasMore else { return }
            loadTransactions(refresh: false)

        case .refresh:
            loadTransactions(refresh: true)

        case .transactionTapped:
            break
        }
    }

    private func loadTransactions(refresh: Bool) {
        if refresh {
            state.nextCursor = ""
            state.hasMore = true
        }

        state.isLoading = true
        Task {
            do {
                let cursor = refresh ? nil : (state.nextCursor.isEmpty ? nil : state.nextCursor)
                let response = try await postAPI.getPaymentList(
                    next: cursor,
                    limit: "20"
                )

                let newTransactions = response.data.map { dto -> Transaction in
                    let thumbnailURL: String? = {
                        guard let post = dto.post, let firstFile = post.files.first else {
                            return nil
                        }
                        return NetworkConfig.baseURL + "/v1" + firstFile
                    }()

                    return Transaction(
                        id: dto.id,
                        productName: dto.productName,
                        price: dto.price,
                        paidAt: dto.paidAt,
                        postId: dto.postId,
                        merchantUid: dto.merchantUid,
                        thumbnailURL: thumbnailURL
                    )
                }

                if refresh {
                    state.transactions = newTransactions
                } else {
                    let existingIds = Set(state.transactions.map { $0.id })
                    let unique = newTransactions.filter { !existingIds.contains($0.id) }
                    state.transactions.append(contentsOf: unique)
                }

                state.nextCursor = response.nextCursor
                state.hasMore = !response.nextCursor.isEmpty && response.nextCursor != "0"
            } catch {
                state.errorMessage = error.localizedDescription
                print("거래 내역 로드 실패: \(error)")
            }
            state.isLoading = false
        }
    }
}
