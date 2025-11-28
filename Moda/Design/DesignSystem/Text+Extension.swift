//
//  Text+Extension.swift
//  Moda
//
//  Created by 금가경 on 11/16/25.
//

import SwiftUI

extension Text {
    func customStyle(fontName: String, fontSize: CGFloat, kerning: CGFloat = -2) -> some View {
        self
            .font(.custom(fontName, size: fontSize))
            .kerning(fontSize * kerning / 100)
    }

    func Logo() -> some View {
        customStyle(fontName: "Cafe24Moyamoya-OTF-Face", fontSize: 24, kerning: 6)
            .foregroundColor(.blue1)
    }

    func H1() -> some View {
        customStyle(fontName: "SUIT-Bold", fontSize: 18)
    }

    func H2() -> some View {
        customStyle(fontName: "SUIT-Bold", fontSize: 16)
    }

    func Body1() -> some View {
        customStyle(fontName: "SUIT-Medium", fontSize: 14)
    }

    func Body2() -> some View {
        customStyle(fontName: "SUIT-Medium", fontSize: 13)
    }
}

extension View {
    func Input() -> some View {
        self.font(.custom("SUIT-Medium", size: 14))
    }
}

