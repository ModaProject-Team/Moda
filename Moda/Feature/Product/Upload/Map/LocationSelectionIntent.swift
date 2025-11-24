//
//  LocationSelectionIntent.swift
//  Moda
//
//  Created by Suji Jang on 11/22/24.
//

import MapKit
import CoreLocation
import SwiftUI

enum LocationSelectionIntent {
    // Map intents
    case updateCameraPosition(MapCameraPosition)
    case moveToLocation(CLLocationCoordinate2D)
    case updateSelectedCoordinate(CLLocationCoordinate2D)

    // Location manager intents
    case setupLocationManager
    case moveToUserLocation
    case requestLocationPermission
    case openAppSettings

    // Alert dismiss intents
    case dismissPermissionDeniedAlert
    case dismissLocationServiceDisabledAlert
    case dismissLocationUpdateFailedAlert
    case retryLocationUpdate

    // Search intents
    case searchTextChanged(String)
    case performSearch
    case selectSearchResult(MKMapItem)
    case clearSearch

    // Place name input intents
    case showPlaceNameInputSheet
    case placeNameChanged(String)
    case confirmLocation
    case dismissPlaceNameInput
}
