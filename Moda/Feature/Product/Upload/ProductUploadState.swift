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
    var uploadedPostId: String?

    // Location data
    var locationName: String = ""
    var latitude: Double?
    var longitude: Double?
    var showLocationSelection: Bool = false

    // 작성 완료 버튼 활성화 조건
    var isFormValid: Bool {
        let hasImages = !selectedImages.isEmpty
        let hasTitle = !title.trimmingCharacters(in: .whitespaces).isEmpty
        let hasPrice = !isSelling || !price.trimmingCharacters(in: .whitespaces).isEmpty
        let hasLocation = !locationName.trimmingCharacters(in: .whitespaces).isEmpty

        return hasImages && hasTitle && hasPrice && hasLocation
    }
}
