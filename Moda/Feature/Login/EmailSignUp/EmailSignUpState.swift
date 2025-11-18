//
//  EmailSignUpState.swift
//  Moda
//
//  Created by 금가경 on 11/17/25.
//

import Foundation

struct EmailSignUpState {
    var isLoading = false
    var errorMessage: String?
    var isSignUpSuccessful = false

    var emailValidationMessage: String?
    var passwordValidationMessage: String?
    var nicknameValidationMessage: String?

    var isEmailValid = false
    var isPasswordValid = false
    var isNicknameValid = false
    var isPasswordMatch = false

    var canSignUp: Bool {
        isEmailValid && isPasswordValid && isNicknameValid && isPasswordMatch && !isLoading
    }
}
