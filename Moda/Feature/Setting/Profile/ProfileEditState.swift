//
//  ProfileEditState.swift
//  Moda
//
//  Created by Suji Jang on 11/24/24.
//

import SwiftUI
import PhotosUI

struct ProfileEditState {
    var nickname: String = ""
    var profileImageURL: URL? = nil
    var selectedImage: UIImage? = nil
    var selectedItem: PhotosPickerItem? = nil

    var isLoading: Bool = false
    var isSaving: Bool = false
    var errorMessage: String? = nil
    var shouldDismiss: Bool = false
}
