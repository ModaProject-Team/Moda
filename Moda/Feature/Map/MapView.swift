//
//  MapView.swift
//  Moda
//
//  Created by Suji Jang on 11/11/25.
//

import SwiftUI
import MapKit

struct MapView: View {
    @StateObject private var store = MapStore()

    var body: some View {
        Map(position: .constant(store.state.cameraPosition))
            .onAppear {
                store.action(.loadInitialLocation)
            }
    }
}

#Preview {
    MapView()
}
