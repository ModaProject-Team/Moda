//
//  LoginIntent.swift
//  Moda
//
//  Created by 금가경 on 11/17/25.
//

import Foundation

enum LoginIntent {
    case loginButtonTapped(email: String, password: String)
    case kakaoLoginTapped
}

