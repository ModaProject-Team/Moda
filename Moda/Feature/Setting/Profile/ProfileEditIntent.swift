//
//  ProfileEditIntent.swift
//  Moda
//
//  Created by Suji Jang on 11/24/24.
//

import PhotosUI
import SwiftUI

enum ProfileEditIntent {
    case onAppear
    case nicknameChanged(String)
    case imageSelected(PhotosPickerItem?)
    case saveTapped
    case dismissError
}
