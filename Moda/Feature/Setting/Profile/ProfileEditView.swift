//
//  ProfileEditView.swift
//  Moda
//
//  Created by Suji Jang on 11/24/24.
//

import SwiftUI
import PhotosUI
import Kingfisher

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = ProfileEditStore()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                if store.state.isLoading {
                    ProgressView("로딩 중...")
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            profileImageSection
                            nicknameSection
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 24)
                    }
                }
            }
            .navigationTitle("프로필 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundColor(.blue1)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("저장") {
                        store.send(.saveTapped)
                    }
                    .font(.body.weight(.semibold))
                    .foregroundColor(.blue1)
                    .disabled(store.state.isSaving)
                }
            }
            .overlay {
                if store.state.isSaving {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView("저장 중...")
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
                }
            }
            .alert("완료", isPresented: $store.state.showSuccessAlert) {
                Button("확인") {
                    dismiss()
                }
            } message: {
                Text("프로필이 저장되었습니다.")
            }
            .alert("오류", isPresented: Binding(
                get: { store.state.errorMessage != nil },
                set: { if !$0 { store.send(.dismissError) } }
            )) {
                Button("확인") {
                    store.send(.dismissError)
                }
            } message: {
                Text(store.state.errorMessage ?? "")
            }
        }
        .task {
            store.send(.onAppear)
        }
    }

    private var profileImageSection: some View {
        PhotosPicker(
            selection: Binding(
                get: { store.state.selectedItem },
                set: { store.send(.imageSelected($0)) }
            ),
            matching: .images,
            photoLibrary: .shared()
        ) {
            ZStack {
                if let selectedImage = store.state.selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else if let url = store.state.profileImageURL {
                    KFImage(url)
                        .requestModifier(KFHeaders.modifier)
                        .placeholder {
                            Circle().fill(Color.gray.opacity(0.2))
                        }
                        .cacheOriginalImage()
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    ZStack {
                        Circle().fill(Color.gray.opacity(0.2))
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 100, height: 100)
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Circle().fill(Color.blue1))
                    }
                }
                .frame(width: 100, height: 100)
            }
        }
    }

    private var nicknameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("닉네임")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField("닉네임을 입력하세요", text: Binding(
                get: { store.state.nickname },
                set: { store.send(.nicknameChanged($0)) }
            ))
            .textFieldStyle(.roundedBorder)
            .autocorrectionDisabled()
        }
    }
}

#Preview {
    ProfileEditView()
}
