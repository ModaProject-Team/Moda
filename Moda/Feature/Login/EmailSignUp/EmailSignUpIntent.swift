//
//  EmailSignUpIntent.swift
//  Moda
//
//  Created by 금가경 on 11/17/25.
//

import Foundation

enum EmailSignUpIntent {
    case emailChanged(String)
    case passwordChanged(String)
    case confirmPasswordChanged(String)
    case nicknameChanged(String)
    case signUpButtonTapped(email: String, password: String, confirmPassword: String, nickname: String)
}
