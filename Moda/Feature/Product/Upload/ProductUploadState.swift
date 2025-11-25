//
//  ProductUploadState.swift
//  Moda
//
//  Created by Suji Jang on 11/15/24.
//

import SwiftUI

enum MediaItem {
    case image(UIImage)
    case video(url: URL, thumbnail: UIImage)
}

struct ProductUploadState {
    var title: String = ""
    var description: String = ""
    var price: String = ""
    var isSelling: Bool = true
    var isPriceNegotiable: Bool = false
    var location: String = ""
    var selectedMedia: [MediaItem] = []
    var isUploading: Bool = false
    var uploadError: String?
    var uploadedPostId: String?
    var showFileSizeAlert: Bool = false

    // Location data
    var locationName: String = ""
    var latitude: Double?
    var longitude: Double?
    var showLocationSelection: Bool = false

    // 작성 완료 버튼 활성화 조건
    var isFormValid: Bool {
        let hasMedia = !selectedMedia.isEmpty
        let hasTitle = !title.trimmingCharacters(in: .whitespaces).isEmpty
        let hasPrice = !isSelling || !price.trimmingCharacters(in: .whitespaces).isEmpty
        let hasLocation = !locationName.trimmingCharacters(in: .whitespaces).isEmpty

        return hasMedia && hasTitle && hasPrice && hasLocation
    }
}
