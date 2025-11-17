//
//  ProductUploadView.swift
//  Moda
//
//  Created by 금가경 on 11/15/24.
//

import SwiftUI

struct ProductUploadState {
    var title: String = ""
    var description: String = ""
    var price: String = ""
    var isSelling: Bool = true
    var isPriceNegotiable: Bool = false
    var location: String = ""
}

enum ProductUploadIntent {
    case titleChanged(String)
    case descriptionChanged(String)
    case priceChanged(String)
    case sellingTypeChanged(Bool)
    case priceNegotiableToggled
    case locationTapped
    case submitButtonTapped
}

final class ProductUploadStore: ObservableObject {
    @Published private(set) var state = ProductUploadState()

    func send(_ intent: ProductUploadIntent) {
        switch intent {
        case .titleChanged(let title):
            state.title = title
        case .descriptionChanged(let description):
            state.description = description
        case .priceChanged(let price):
            state.price = price
        case .sellingTypeChanged(let isSelling):
            state.isSelling = isSelling
        case .priceNegotiableToggled:
            state.isPriceNegotiable.toggle()
        case .locationTapped:
            break
        case .submitButtonTapped:
            break
        }
    }
}

struct ProductUploadView: View {
    @StateObject private var store = ProductUploadStore()
    @EnvironmentObject var navigator: AppNavigator

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
        }
        .navigationBarHidden(true)
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

            Text("내 물건 팔기")
                .H1()
                .foregroundColor(.gray1)

            Spacer()

            Button {
                // TODO: 임시저장
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
            Button {
                // TODO: 사진 선택
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "camera")
                        .font(.system(size: 24))
                        .foregroundColor(.gray2)

                    Text("0/10")
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

                    Text("위치 추가")
                        .Body2()
                        .foregroundColor(.gray2)

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
            Divider()

            Button {
                store.send(.submitButtonTapped)
            } label: {
                Text("작성 완료")
                    .H2()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue1)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
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
