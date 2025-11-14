//
//  FriendSearchView.swift
//  Moda
//
//  Created by hyunMac on 11/12/25.
//

import SwiftUI

// MARK: - View
struct FriendSearchView: View {
    @State private var searchText: String = ""
    @FocusState private var isSearching: Bool

    var body: some View {
        VStack(spacing: 0) {
            // 상단 검색 영역
            HStack(spacing: 8) {
                SearchField(
                    text: $searchText,
                    isFocused: _isSearching,
                    onClear: { searchText = "" }
                )
                .padding(.vertical, 8)

                Button("취소") {
                    // TODO: 이전 화면으로 나가기 추가 필요
                    searchText = ""
                    isSearching = false
                }
                .foregroundStyle(.black)
            }
            .padding(.horizontal, 12)
            .background(.ultraThinMaterial)

            //TODO: 친구 목록 영역 추가 필요
            Spacer()
        }
    }
}

// MARK: - Search Field
private struct SearchField: View {
    @Binding var text: String
    @FocusState var isFocused: Bool

    var onClear: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("검색", text: $text)
                .textInputAutocapitalization(.none)
                .disableAutocorrection(true)
                .focused($isFocused)
                .submitLabel(.search)

            if !text.isEmpty {
                Button {
                    onClear()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
        )
    }
}

#Preview {
    NavigationStack {
        FriendSearchView()
    }
}
