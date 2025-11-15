//
//  HomeView.swift
//  Moda
//
//  Created by 금가경 on 11/15/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var navigator: AppNavigator

    var body: some View {
        VStack(spacing: 20) {
            Text("홈 화면")
                .font(.largeTitle)
                .fontWeight(.bold)

            uploadButton

            Spacer()
        }
        .padding()
    }

    private var uploadButton: some View {
        Button {
            navigator.push(.productUpload)
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("물건 올리기")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(AppNavigator.shared)
    }
}
