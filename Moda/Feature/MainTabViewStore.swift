//
//  MainTabViewStore.swift
//  Moda
//
//  Created by 금가경 on 11/29/25.
//

import SwiftUI

final class MainTabViewStore: ObservableObject {
    @Published private(set) var state = MainTabViewState()

    func send(_ intent: MainTabViewIntent) {
        switch intent {
        case .tabSelected(let tab):
            state.selectedTab = tab
        }
    }
}
