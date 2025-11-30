//
//  PlaceNameInputView.swift
//  Moda
//
//  Created by Suji Jang on 11/22/24.
//

import SwiftUI

struct PlaceNameInputView: View {

    @Binding var placeName: String
    var onConfirm: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button {
                    onCancel()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18))
                        .foregroundColor(.gray1)
                }

                Spacer()

                Text("거래 장소 설정")
                    .H1()
                    .foregroundColor(.gray1)

                Spacer()

                Image(systemName: "xmark")
                    .font(.system(size: 18))
                    .foregroundColor(.clear)
            }
            .padding(.top, 20)
            .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 8) {
                Text("선택한 곳의 장소명을 입력해주세요")
                    .Body2()
                    .foregroundColor(.gray2)

                TextField("예) 강남역 1번 출구, 교보타워 앞", text: $placeName)
                    .Input()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.gray5)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 16)

            Spacer()

            Button {
                onConfirm()
            } label: {
                Text("거래 장소 등록")
                    .H2()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(placeName.isEmpty ? Color.gray3 : Color.blue1)
                    .cornerRadius(12)
            }
            .disabled(placeName.isEmpty)
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
}

#Preview {
    PlaceNameInputView(
        placeName: .constant(""),
        onConfirm: {},
        onCancel: {}
    )
}
