//
//  SettingState.swift
//  Moda
//
//  Created by Suji Jang on 11/24/24.
//

import Foundation

struct SettingState {
    var nickname: String = ""
    var profileImageURL: URL? = nil
    var latestPostImageURL: URL? = nil

    var isLoading: Bool = false
    var errorMessage: String? = nil
    var isWithdrawing: Bool = false
}
