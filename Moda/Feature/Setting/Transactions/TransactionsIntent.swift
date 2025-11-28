//
//  TransactionsIntent.swift
//  Moda
//
//  Created by Suji Jang on 11/27/25.
//

import Foundation

enum TransactionsIntent {
    case onAppear
    case loadMore
    case refresh
    case transactionTapped(String) // postId
}
