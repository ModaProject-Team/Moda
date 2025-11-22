//
//  TradeLocationView.swift
//  Moda
//
//  Created by Claude on 11/22/24.
//

import SwiftUI
import MapKit

struct TradeLocationView: View {
    let title: String
    let coordinate: CLLocationCoordinate2D
    let onMapTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("거래 희망 장소")
                    .H2()
                    .foregroundColor(.black)

                Text(title)
                    .H2()
                    .foregroundColor(.gray2)
            }

            ZStack {
                Map(initialPosition: .region(
                    MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
                    )
                )) {
                    Annotation("", coordinate: coordinate) {
                        Image("pin")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                    }
                }
                .disabled(true)
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            }
            .contentShape(Rectangle())
            .onTapGesture {
                onMapTap()
            }
        }
    }
}

#Preview {
    TradeLocationView(
        title: "마콘 카페",
        coordinate: CLLocationCoordinate2D(latitude: 37.5172, longitude: 126.8945),
        onMapTap: {}
    )
    .padding()
    .background(Color.white)
}
