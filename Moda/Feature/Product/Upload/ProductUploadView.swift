//
//  ProductUploadView.swift
//  Moda
//
//  Created by 금가경 on 11/15/24.
//

import SwiftUI
import PhotosUI

struct ProductUploadView: View {

    let editMode: Bool
    let postId: String?

    @StateObject private var store: ProductUploadStore
    @EnvironmentObject var navigator: AppNavigator
    @State private var selectedItems: [PhotosPickerItem] = []

    init(editMode: Bool = false, postId: String? = nil) {
        self.editMode = editMode
        self.postId = postId
        self._store = StateObject(wrappedValue: ProductUploadStore(editMode: editMode, postId: postId))
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        photoSection
                        titleSection
                        descriptionSection
                        priceSection
                        locationSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }

                submitButtonSection
            }
            .disabled(store.state.isUploading)

            // 업로드 중 전체 화면 오버레이
            if store.state.isUploading {
                ZStack {
                    LoadingOverlay()

                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)

                        Text("업로드 중...")
                            .H2()
                            .foregroundColor(.white)
                    }
                }
                .onTapGesture { }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: Binding(
            get: { store.state.showLocationSelection },
            set: { if !$0 { store.send(.dismissLocationSelection) } }
        )) {
            LocationSelectionView(onLocationSelected: { name, latitude, longitude in
                store.send(.locationSelected(name, latitude, longitude))
            })
        }
        .onChange(of: store.state.uploadedPostId) { _, postId in
            if let postId = postId {
                navigator.popToRoot()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    navigator.push(.productDetail(postId: postId))
                }
            }
        }
        .alert(
            "동영상 용량 초과",
            isPresented: Binding(
                get: { store.state.showFileSizeAlert },
                set: { if !$0 { store.send(.dismissFileSizeAlert) } }
            )
        ) {
            Button("확인", role: .cancel) {
                store.send(.dismissFileSizeAlert)
            }
        } message: {
            Text("동영상은 10MB 이하만 업로드 가능합니다.")
        }
    }

    private var headerSection: some View {
        HStack {
            Button {
                navigator.pop()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18))
                    .foregroundColor(.gray1)
            }

            Spacer()

            Text(editMode ? "게시글 수정하기" : "내 물건 팔기")
                .H1()
                .foregroundColor(.gray1)

            Spacer()

            Button {
            } label: {
                Text("임시저장")
                    .Body2()
                    .foregroundColor(.gray2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: 5 - store.state.selectedMedia.count,
                        matching: .any(of: [.images, .videos])
                    ) {
                        VStack(spacing: 4) {
                            Image(systemName: "camera")
                                .font(.system(size: 24))
                                .foregroundColor(.gray2)

                            Text("\(store.state.selectedMedia.count)/5")
                                .Body2()
                                .foregroundColor(.gray2)
                        }
                        .frame(width: 70, height: 70)
                        .background(Color.gray5)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray3, lineWidth: 1)
                        )
                    }
                    .onChange(of: selectedItems) {
                        store.send(.imagesSelected(selectedItems))
                        selectedItems = []
                    }
                    .padding(.vertical, 8)

                    ForEach(Array(store.state.selectedMedia.enumerated()), id: \.offset) { index, media in
                        ZStack(alignment: .topTrailing) {
                            switch media {
                            case .image(let image, _):
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 70, height: 70)
                                    .cornerRadius(12)
                                    .clipped()

                            case .video(_, let thumbnail, _):
                                ZStack {
                                    Image(uiImage: thumbnail)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 70, height: 70)
                                        .cornerRadius(12)
                                        .clipped()

                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                }
                            }

                            Button {
                                store.send(.imageRemoved(index))
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.black.opacity(0.5)))
                            }
                            .offset(x: 5, y: -5)
                        }
                    }
                }
            }
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("제목")
                .Body2()
                .foregroundColor(.gray2)

            TextField("글 제목", text: Binding(
                get: { store.state.title },
                set: { store.send(.titleChanged($0)) }
            ))
            .Input()
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.gray5)
            .cornerRadius(8)
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("자세한 설명")
                .Body2()
                .foregroundColor(.gray2)

            ZStack(alignment: .topLeading) {
                if store.state.description.isEmpty {
                    Text("물건에 대해 자세히 설명해주세요.\n\n상태, 구매 시기, 사용감 등을 적으면 친구들이 더 쉽게 이해할 수 있어요.")
                        .Body1()
                        .foregroundColor(.gray3)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }

                TextEditor(text: Binding(
                    get: { store.state.description },
                    set: { store.send(.descriptionChanged($0)) }
                ))
                .Input()
                .frame(minHeight: 120)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .scrollContentBackground(.hidden)
            }
            .background(Color.gray5)
            .cornerRadius(8)

            Button {
                // TODO: 자주 쓰는 문구
            } label: {
                Text("자주 쓰는 문구")
                    .Body2()
                    .foregroundColor(.gray1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray3, lineWidth: 1)
                    )
            }
        }
    }

    private var priceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("가격")
                .Body2()
                .foregroundColor(.gray2)

            HStack(spacing: 8) {
                Button {
                    store.send(.sellingTypeChanged(true))
                } label: {
                    Text("판매하기")
                        .Body1()
                        .foregroundColor(store.state.isSelling ? .white : .gray1)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(store.state.isSelling ? Color.gray1 : Color.gray5)
                        .clipShape(Capsule())
                }

                Button {
                    store.send(.sellingTypeChanged(false))
                } label: {
                    Text("나눔하기")
                        .Body1()
                        .foregroundColor(!store.state.isSelling ? .white : .gray1)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(!store.state.isSelling ? Color.gray1 : Color.gray5)
                        .clipShape(Capsule())
                }

                Spacer()
            }

            if store.state.isSelling {
                HStack {
                    Text("₩")
                        .Body1()
                        .foregroundColor(.gray2)

                    TextField("가격을 입력해주세요.", text: Binding(
                        get: { store.state.price },
                        set: { store.send(.priceChanged($0)) }
                    ))
                    .Input()
                    .keyboardType(.numberPad)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.gray3)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.gray5)
                .cornerRadius(8)

                HStack(spacing: 8) {
                    Button {
                        store.send(.priceNegotiableToggled)
                    } label: {
                        Image(systemName: store.state.isPriceNegotiable ? "checkmark.square.fill" : "square")
                            .font(.system(size: 20))
                            .foregroundColor(store.state.isPriceNegotiable ? .blue1 : .gray3)
                    }

                    Text("가격 제안 받기")
                        .Body1()
                        .foregroundColor(.gray1)
                }
            }
        }
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("거래 정보")
                .Body2()
                .foregroundColor(.gray2)

            Button {
                store.send(.locationTapped)
            } label: {
                HStack {
                    Text("거래 희망 장소")
                        .Body1()
                        .foregroundColor(.gray1)

                    Spacer()

                    Text(store.state.locationName.isEmpty ? "위치 추가" : store.state.locationName)
                        .Body2()
                        .foregroundColor(store.state.locationName.isEmpty ? .gray2 : .blue1)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.gray3)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.gray5)
                .cornerRadius(8)
            }
        }
    }

    private var submitButtonSection: some View {
        VStack(spacing: 0) {
            // 에러 메시지 표시
            if let error = store.state.uploadError {
                Text(error)
                    .Body2()
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }

            Divider()

            Button {
                store.send(.submitButtonTapped)
            } label: {
                Text("작성 완료")
                    .H2()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .background(store.state.isFormValid ? Color.blue1 : Color.gray3)
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .disabled(!store.state.isFormValid)
        }
        .background(Color.white)
    }
}

#Preview {
    NavigationStack {
        ProductUploadView()
            .environmentObject(AppNavigator.shared)
    }
}
