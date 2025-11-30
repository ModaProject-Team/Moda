//
//  LocationSelectionView.swift
//  Moda
//
//  Created by Suji Jang on 11/22/24.
//

import SwiftUI
import MapKit

struct LocationSelectionView: View {

    @StateObject private var store = LocationSelectionStore()
    @Environment(\.dismiss) private var dismiss
    var onLocationSelected: ((String, Double, Double) -> Void)?

    var body: some View {
        ZStack {
            Map(position: Binding(
                get: { store.state.cameraPosition },
                set: { store.send(.updateCameraPosition($0)) }
            )) {
                UserAnnotation()
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                store.send(.updateSelectedCoordinate(context.region.center))
            }
            .mapControls { }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Image("pin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                }
                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)

                Spacer()
            }
            .ignoresSafeArea(.keyboard)

            VStack {
                searchBar
                    .padding(.top, 8)

                // 검색 결과 또는 "결과 없음" 표시
                if !store.state.searchResults.isEmpty {
                    searchResultsList
                } else if store.state.hasSearched && store.state.searchResults.isEmpty {
                    noSearchResultsView
                }

                Spacer()
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        withAnimation {
                            store.send(.moveToUserLocation)
                        }
                    } label: {
                        Image(systemName: "dot.scope")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(.all, 8)
                            .background(Color.blue1)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                    .padding(.top, 80)
                    .padding(.trailing, 16)
                }
                Spacer()
                
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18))
                            .foregroundColor(.gray1)
                            .padding(12)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                    .padding(.leading, 16)
                    
                    Spacer()
                    
                    Button {
                        store.send(.showPlaceNameInputSheet)
                    } label: {
                        Text("선택 완료")
                            .H2()
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue1)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 16)
            }
        }
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    hideKeyboard()
                }
        )
        .navigationBarHidden(true)
        .onAppear {
            store.send(.setupLocationManager)
            if let handler = onLocationSelected {
                store.setCompletionHandler(handler)
            }
        }
        .alert(
            "위치 서비스를 사용할 수 없습니다",
            isPresented: Binding(
                get: { store.state.showLocationServiceDisabledAlert },
                set: { if !$0 { store.send(.dismissLocationServiceDisabledAlert) } }
            )
        ) {
            Button("확인", role: .cancel) {
                store.send(.dismissLocationServiceDisabledAlert)
            }
        } message: {
            Text("iPhone 설정 > 개인정보 보호 및 보안에서 위치 서비스를 켜주세요.")
        }
        .alert(
            "위치 권한이 거부되었습니다",
            isPresented: Binding(
                get: { store.state.showPermissionDeniedAlert },
                set: { if !$0 { store.send(.dismissPermissionDeniedAlert) } }
            )
        ) {
            Button("취소", role: .cancel) {
                store.send(.dismissPermissionDeniedAlert)
            }
            Button("설정으로 이동") {
                store.send(.openAppSettings)
                store.send(.dismissPermissionDeniedAlert)
            }
        } message: {
            Text("앱에서 위치 기능을 사용하려면 설정에서 권한을 허용해주세요.")
        }
        .alert(
            "위치를 가져올 수 없습니다",
            isPresented: Binding(
                get: { store.state.showLocationUpdateFailedAlert },
                set: { if !$0 { store.send(.dismissLocationUpdateFailedAlert) } }
            )
        ) {
            Button("취소", role: .cancel) {
                store.send(.dismissLocationUpdateFailedAlert)
            }
            Button("재시도") {
                store.send(.retryLocationUpdate)
            }
        } message: {
            Text("현재 위치를 가져오는 중 문제가 발생했습니다. 다시 시도해주세요.")
        }
        .sheet(isPresented: Binding(
            get: { store.state.showPlaceNameInput },
            set: { if !$0 { store.send(.dismissPlaceNameInput) } }
        )) {
            PlaceNameInputView(
                placeName: Binding(
                    get: { store.state.placeName },
                    set: { store.send(.placeNameChanged($0)) }
                ),
                onConfirm: {
                    store.send(.confirmLocation)
                    dismiss()
                },
                onCancel: {
                    store.send(.dismissPlaceNameInput)
                }
            )
            .presentationDetents([.height(250)])
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray2)

                TextField("장소 검색", text: Binding(
                    get: { store.state.searchText },
                    set: { store.send(.searchTextChanged($0)) }
                ))
                .Input()
                .onSubmit {
                    store.send(.performSearch)
                }

                if !store.state.searchText.isEmpty {
                    Button {
                        store.send(.clearSearch)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray3)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 3)

            if store.state.isSearching {
                ProgressView()
                    .padding(.trailing, 8)
            }
        }
        .padding(.horizontal, 16)
    }

    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(store.state.searchResults, id: \.self) { item in
                    Button {
                        store.send(.selectSearchResult(item))
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name ?? "알 수 없는 장소")
                                .Body1()
                                .foregroundColor(.gray1)

                            if let address = item.placemark.title {
                                Text(address)
                                    .Body2()
                                    .foregroundColor(.gray2)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Divider()
                }
            }
        }
        .frame(maxHeight: min(CGFloat(store.state.searchResults.count) * 70, 300))
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 3)
        .padding(.horizontal, 16)
    }

    private var noSearchResultsView: some View {
        VStack {
            Text("검색 결과가 없습니다.")
                .Body1()
                .foregroundColor(.gray2)
                .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 3)
        .padding(.horizontal, 16)
    }
}

#Preview {
    LocationSelectionView()
}
