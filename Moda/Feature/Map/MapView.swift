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
                store.send(.setupLocationManager)
                store.send(.loadInitialLocation)
            }
            .alert(
                "위치 서비스를 사용할 수 없습니다",
                isPresented: Binding(
                    get: { store.state.showLocationAlert },
                    set: { if !$0 { store.send(.dismissLocationAlert) } }
                )) {
                    Button("확인", role: .cancel) {
                        store.send(.dismissLocationAlert)
                    }
            } message: {
                Text("'iPhone 설정 > 개인정보 보호 및 보안'에서 위치 서비스를 켜주세요.")
            }
    }
}

#Preview {
    MapView()
}
