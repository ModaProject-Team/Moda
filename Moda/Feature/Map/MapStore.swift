//
//  MapStore.swift
//  Moda
//
//  Created by Suji Jang on 11/15/25.
//

import SwiftUI
import MapKit

@MainActor

final class MapStore: ObservableObject {
    @Published private(set) var state = MapState.initial

    func action(_ intent: MapIntent) {
        switch intent {
        case .updateCameraPosition(let position):
            state.cameraPosition = position

        case .moveToLocation(let coordinate):
            state.cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
                )
            )

        case .loadInitialLocation:
            //TODO: 권한 설정 후 진입 위치 수정하기
            state = .initial
        }
    }
}
