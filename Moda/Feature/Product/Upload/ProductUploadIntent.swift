//
//  ProductUploadIntent.swift
//  Moda
//
//  Created by Suji Jang on 11/15/24.
//

import SwiftUI
import PhotosUI

enum ProductUploadIntent {
    case titleChanged(String)
    case descriptionChanged(String)
    case priceChanged(String)
    case sellingTypeChanged(Bool)
    case priceNegotiableToggled
    case locationTapped
    case locationSelected(String, Double, Double)
    case dismissLocationSelection
    case imagesSelected([PhotosPickerItem])
    case imageRemoved(Int)
    case submitButtonTapped
}
