//
//  LocationSelectionState.swift
//  Moda
//
//  Created by Suji Jang on 11/22/24.
//

import SwiftUI
import MapKit
import CoreLocation

struct LocationSelectionState {
    // Map state
    var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780), // 서울 기본 위치
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )
    var currentLocation: CLLocationCoordinate2D?
    var selectedCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)

    // Search state
    var searchText: String = ""
    var searchResults: [MKMapItem] = []
    var isSearching: Bool = false
    var hasSearched: Bool = false  // 검색 실행 여부

    // Location permission state
    var isLocationServicesEnabled: Bool = true
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var showLocationServiceDisabledAlert: Bool = false
    var showPermissionDeniedAlert: Bool = false
    var showLocationUpdateFailedAlert: Bool = false

    // Sheet state
    var showPlaceNameInput: Bool = false
    var placeName: String = ""

    // Completion handler
    var onLocationSelected: ((String, Double, Double) -> Void)?
}
