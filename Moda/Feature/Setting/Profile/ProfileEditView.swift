//
//  ProfileEditView.swift
//  Moda
//
//  Created by Suji Jang on 11/24/24.
//

import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @EnvironmentObject var navigator: AppNavigator
    @State private var store = ProfileEditStore()

    var body: some View {
        ZStack {
                Color.white.ignoresSafeArea()

                if store.state.isLoading {
                    ProgressView("로딩 중...")
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            profileImageSection

                            VStack(spacing: 16) {
                                nicknameSection
                                statusMessageSection
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 24)
                    }
                }
            }
            .navigationTitle("프로필 편집")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        navigator.pop()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18))
                            .foregroundColor(.gray1)
                    }
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
            .enableSwipeBack()
            .overlay {
                if store.state.isSaving {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView("저장 중...")
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
                }
            }
            .onChange(of: store.state.shouldDismiss) { _, shouldDismiss in
                if shouldDismiss {
                    navigator.pop()
                }
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
            .task {
                store.send(.onAppear)
            }
    }

    private var profileImageSection: some View {
        let selectedImage = store.state.selectedImage
        let profileImageURL = store.state.profileImageURL

        return PhotosPicker(
            selection: Binding(
                get: { MainActor.assumeIsolated { store.state.selectedItem } },
                set: { newValue in MainActor.assumeIsolated { store.send(.imageSelected(newValue)) } }
            ),
            matching: .images,
            photoLibrary: .shared()
        ) {
            ProfileImageContent(
                selectedImage: selectedImage,
                profileImageURL: profileImageURL
            )
        }
    }

    private var nicknameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("닉네임")
                .Body1()
                .foregroundColor(.gray1)

            TextField("닉네임을 입력하세요", text: Binding(
                get: { MainActor.assumeIsolated { store.state.nickname } },
                set: { newValue in MainActor.assumeIsolated { store.send(.nicknameChanged(newValue)) } }
            ))
            .Input()
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.gray5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.gray4, lineWidth: 1)
            )
            .autocorrectionDisabled()
        }
    }

    private var statusMessageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("상태메시지")
                .Body1()
                .foregroundColor(.gray1)

            TextField("상태메시지를 입력하세요", text: Binding(
                get: { MainActor.assumeIsolated { store.state.statusMessage } },
                set: { newValue in MainActor.assumeIsolated { store.send(.statusMessageChanged(newValue)) } }
            ))
            .Input()
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.gray5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.gray4, lineWidth: 1)
            )
            .autocorrectionDisabled()
        }
    }
}

// MARK: - Profile Image Content
private struct ProfileImageContent: View {
    let selectedImage: UIImage?
    let profileImageURL: URL?

    var body: some View {
        ZStack {
            Group {
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else if let url = profileImageURL {
                    CachedImageView(
                        url: url,
                        targetSize: CGSize(width: 100, height: 100),
                        contentMode: .fill,
                        placeholder: {
                            AnyView(Circle().fill(Color.gray.opacity(0.2)))
                        }
                    )
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

#Preview {
    ProfileEditView()
}
