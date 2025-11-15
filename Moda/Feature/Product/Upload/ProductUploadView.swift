//
//  ProductUploadView.swift
//  Moda
//
//  Created by 금가경 on 11/15/24.
//

import SwiftUI

// MARK: - State
struct ProductUploadState {
    var productTitle = ""
    var productDescription = ""
    var isUploading = false
}

// MARK: - Intent
enum ProductUploadIntent {
    case titleChanged(String)
    case descriptionChanged(String)
    case uploadButtonTapped
}

// MARK: - Store
final class ProductUploadStore: ObservableObject {
    @Published private(set) var state = ProductUploadState()

    func send(_ intent: ProductUploadIntent) {
        switch intent {
        case .titleChanged(let title):
            state.productTitle = title
        case .descriptionChanged(let description):
            state.productDescription = description
        case .uploadButtonTapped:
            uploadProduct()
        }
    }

    private func uploadProduct() {
        state.isUploading = true
        // TODO: 실제 업로드 로직 구현
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.state.isUploading = false
            // TODO: 업로드 완료 후 처리
        }
    }
}

// MARK: - View
struct ProductUploadView: View {
    @StateObject private var store = ProductUploadStore()
    @EnvironmentObject var navigator: AppNavigator

    var body: some View {
        VStack(spacing: 20) {
            Text("물건 올리기")
                .font(.largeTitle)
                .fontWeight(.bold)

            formSection

            uploadButton

            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
    }

    private var formSection: some View {
        VStack(spacing: 16) {
            TextField("물건 제목", text: Binding(
                get: { store.state.productTitle },
                set: { store.send(.titleChanged($0)) }
            ))
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal)

            TextEditor(text: Binding(
                get: { store.state.productDescription },
                set: { store.send(.descriptionChanged($0)) }
            ))
            .frame(height: 150)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal)
        }
    }

    private var uploadButton: some View {
        Button {
            store.send(.uploadButtonTapped)
        } label: {
            if store.state.isUploading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Text("업로드")
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(10)
        .padding(.horizontal)
        .disabled(store.state.isUploading || store.state.productTitle.isEmpty)
        .opacity(store.state.productTitle.isEmpty ? 0.5 : 1.0)
    }
}

#Preview {
    NavigationStack {
        ProductUploadView()
            .environmentObject(AppNavigator.shared)
    }
}
