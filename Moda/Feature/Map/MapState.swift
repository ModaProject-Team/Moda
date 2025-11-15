//
//  MapState.swift
//  Moda
//
//  Created by Suji Jang on 11/15/25.
//

import SwiftUI
import MapKit

struct MapState {
    var cameraPosition: MapCameraPosition

    static let initial = MapState(
        cameraPosition: .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780), // 서울 시청
                span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
            )
        )
    )
}
