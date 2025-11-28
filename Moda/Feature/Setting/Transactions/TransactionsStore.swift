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
            state.errorMessage = nil
        }

        state.isLoading = true
        Task {
            do {
                let cursor = refresh ? nil : (state.nextCursor.isEmpty ? nil : state.nextCursor)
                let response = try await postAPI.getPaymentList(
                    next: cursor,
                    limit: "20"
                )

                // 각 post_id로 게시글 정보 조회하여 썸네일 가져오기
                let newTransactions = await withTaskGroup(of: (String, Transaction?).self) { group in
                    for dto in response.data {
                        group.addTask {
                            do {
                                let post = try await self.postAPI.getPost(postId: dto.postId)
                                let thumbnailURL = post.files.first.map { NetworkConfig.baseURL + "/v1" + $0 }

                                let transaction = Transaction(
                                    id: dto.id,
                                    productName: dto.productName,
                                    price: dto.price,
                                    paidAt: dto.paidAt,
                                    postId: dto.postId,
                                    merchantUid: dto.merchantUid,
                                    thumbnailURL: thumbnailURL
                                )
                                return (dto.id, transaction)
                            } catch {
                                // 게시글 조회 실패해도 거래 내역은 표시 (썸네일만 없음)
                                let transaction = Transaction(
                                    id: dto.id,
                                    productName: dto.productName,
                                    price: dto.price,
                                    paidAt: dto.paidAt,
                                    postId: dto.postId,
                                    merchantUid: dto.merchantUid,
                                    thumbnailURL: nil
                                )
                                return (dto.id, transaction)
                            }
                        }
                    }

                    var results: [String: Transaction] = [:]
                    for await (id, transaction) in group {
                        if let transaction = transaction {
                            results[id] = transaction
                        }
                    }

                    // 원본 순서 유지
                    return response.data.compactMap { dto in
                        results[dto.id]
                    }
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
            }
            state.isLoading = false
        }
    }
}
