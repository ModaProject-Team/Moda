//
//  EmailSignUpStore.swift
//  Moda
//
//  Created by 금가경 on 11/17/25.
//

import SwiftUI

final class EmailSignUpStore: ObservableObject {
    @Published private(set) var state = EmailSignUpState()

    func send(_ intent: EmailSignUpIntent) {

    }
}
