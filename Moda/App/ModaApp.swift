//
//  ModaApp.swift
//  Moda
//
//  Created by 금가경 on 11/6/25.
//

import SwiftUI

@main
struct ModaApp: App {
    @StateObject private var navigator = AppNavigator.shared
    
    var body: some Scene {
        WindowGroup {
            
            NavigationStack(path: $navigator.path) {
                HomeView()
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        destination.view()
                    }
            }
            .environmentObject(navigator)
            
            
            
//            MapView()
        }
    }
}
