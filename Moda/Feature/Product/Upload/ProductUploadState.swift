//
//  ProductUploadState.swift
//  Moda
//
//  Created by Suji Jang on 11/15/24.
//

import SwiftUI

struct ProductUploadState {
    var title: String = ""
    var description: String = ""
    var price: String = ""
    var isSelling: Bool = true
    var isPriceNegotiable: Bool = false
    var location: String = ""
    var selectedImages: [UIImage] = []
    var isUploading: Bool = false
    var uploadError: String?
}
