//
//  View+Keyboard.swift
//  Moda
//
//  Created by 금가경 on 11/30/24.
//

import SwiftUI

extension View {
    /// 키보드를 내리는 함수
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    /// 화면을 탭하거나 드래그하면 키보드가 내려가도록 하는 Modifier
    func dismissKeyboardOnInteraction() -> some View {
        self
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        hideKeyboard()
                    }
            )
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { _ in
                        hideKeyboard()
                    }
            )
    }
}
