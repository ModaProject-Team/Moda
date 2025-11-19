//
//  KFHeaders.swift
//  Moda
//
//  Created by hyunMac on 11/19/25.
//

import Kingfisher

// MARK: - Kingfisher Headers
enum KFHeaders {
    static let sesacKey: String = NetworkConfig.sesacKey
    static let productId: String = NetworkConfig.productId
    static let authorization: String = TokenManager.shared.accessToken ?? ""

    static var modifier: AnyModifier {
        AnyModifier { request in
            var r = request
            r.setValue(sesacKey, forHTTPHeaderField: "SesacKey")
            r.setValue(productId, forHTTPHeaderField: "ProductId")
            r.setValue(authorization, forHTTPHeaderField: "Authorization")
            return r
        }
    }
}
