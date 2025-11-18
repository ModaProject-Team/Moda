//
//  AuthTextField.swift
//  Moda
//
//  Created by 금가경 on 11/18/25.
//

import SwiftUI

struct AuthTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    let keyboardType: UIKeyboardType
    let validationMessage: String?
    let isValid: Bool
    let showValidation: Bool

    init(
        label: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        validationMessage: String? = nil,
        isValid: Bool = false,
        showValidation: Bool = false
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.validationMessage = validationMessage
        self.isValid = isValid
        self.showValidation = showValidation
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .Body2()
                .foregroundColor(.gray2)

            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .Body1()
                        .foregroundColor(.gray3)
                        .padding(.horizontal, 16)
                }

                if isSecure {
                    SecureField("", text: $text)
                        .Input()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                } else {
                    TextField("", text: $text)
                        .Input()
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }
            }
            .background(Color.gray5)
            .cornerRadius(8)

            if showValidation, let message = validationMessage, !text.isEmpty {
                Text(message)
                    .Body2()
                    .foregroundColor(isValid ? .blue1 : .red)
            }
        }
    }
}
