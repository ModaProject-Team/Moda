//
//  MapView.swift
//  Moda
//
//  Created by Suji Jang on 11/11/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    @StateObject private var store = MapStore()

    var body: some View {
        Map(position: Binding(
            get: { store.state.cameraPosition },
            set: { store.send(.updateCameraPosition($0)) }
        ))
            .onAppear {
                store.send(.setupLocationManager)
            }
            .alert(
                "위치 서비스를 사용할 수 없습니다",
                isPresented: Binding(
                    get: { store.state.showLocationServiceDisabledAlert },
                    set: { if !$0 { store.send(.dismissLocationServiceDisabledAlert) } }
                )
            ) {
                Button("확인", role: .cancel) {
                    store.send(.dismissLocationServiceDisabledAlert)
                }
            } message: {
                Text("iPhone 설정 > 개인정보 보호 및 보안에서 위치 서비스를 켜주세요.")
            }
            .alert(
                "위치 권한이 거부되었습니다",
                isPresented: Binding(
                    get: { store.state.showPermissionDeniedAlert },
                    set: { if !$0 { store.send(.dismissPermissionDeniedAlert) } }
                )
            ) {
                Button("취소", role: .cancel) {
                    store.send(.dismissPermissionDeniedAlert)
                }
                Button("설정으로 이동") {
                    store.send(.openAppSettings)
                    store.send(.dismissPermissionDeniedAlert)
                }
            } message: {
                Text("앱에서 위치 기능을 사용하려면 설정에서 권한을 허용해주세요.")
            }
    }
}

#Preview {
    MapView()
}
