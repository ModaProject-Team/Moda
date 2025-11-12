//
//  MapView.swift
//  Moda
//
//  Created by Suji Jang on 11/11/25.
//

import SwiftUI
import MapKit

struct MapView: View {

    //TODO: 권한 설정 후 진입 위치 수정하기
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780), // 서울
            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        )
    )

    var body: some View {
        Map(position: $cameraPosition)
    }
}

#Preview {
    MapView()
}
