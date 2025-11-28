//
//  Colors.swift
//  Moda
//
//  Created by 금가경 on 11/16/25.
//

import SwiftUI

extension Color {
    init(hex: String, opacity: Double = 1.0) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")

        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let red = Double((rgb >> 16) & 0xff) / 255
        let green = Double((rgb >> 8) & 0xff) / 255
        let blue = Double((rgb >> 0) & 0xff) / 255

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}

extension Color {
    static var blue1: Self {
        .init(hex: "#A0C5FF")
    }

    static var green1: Self {
        .init(hex: "#C6EF94")
    }

    static var pink1: Self {
        .init(hex: "#FFCAC9")
    }

    static var gray1: Self {
        .init(hex: "#262633")
    }

    static var gray2: Self {
        .init(hex: "#262633", opacity: 0.6)
    }

    static var gray3: Self {
        .init(hex: "#D9D9D9")
    }

    static var gray4: Self {
        .init(hex: "#F0F0F0")
    }

    static var gray5: Self {
        .init(hex: "#F5F5F5")
    }

    static var inkGray: Self {
        .init(hex: "#3A3A3A")
    }
}
