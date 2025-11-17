//
//  LoginStore.swift
//  Moda
//
//  Created by 금가경 on 11/17/25.
//

import SwiftUI

final class LoginStore: ObservableObject {
    @Published private(set) var state = LoginState()

    func send(_ intent: LoginIntent) {

    }
}
