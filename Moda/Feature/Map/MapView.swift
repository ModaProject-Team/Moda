//
//  MapView.swift
//  Moda
//
//  Created by Suji Jang on 11/11/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    @StateObject private var store = MapStore()
    
    var body: some View {
        ZStack {
            Map(position: Binding(
                get: { store.state.cameraPosition },
                set: { store.send(.updateCameraPosition($0)) }
            )) {
                UserAnnotation()

                ForEach(store.state.posts) { post in
                    Annotation(post.title, coordinate: post.coordinate) {
                        CustomAnnotationView(
                            post: post,
                            isSelected: store.state.selectedPostId == post.id
                        )
                        .onTapGesture {
                            withAnimation {
                                if store.state.selectedPostId == post.id {
                                    store.send(.selectPost(nil))
                                } else {
                                    store.send(.selectPost(post.id))
                                }
                            }
                        }
                    }
                }
            }
            .onMapCameraChange { context in
                store.send(.updateSpan(context.region.span))
            }
            .ignoresSafeArea()

            // 우측 상단 현재 위치 버튼
            VStack {
                HStack {
                    Spacer()
                    VStack {
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
                        .padding(.top, 8)
                        .padding(.trailing, 16)

                        Spacer()
                    }
                }
            }

            // 하단 게시물 카드
            if store.state.selectedPostIndex != nil {
                VStack {
                    Spacer()

                    TabView(selection: Binding(
                        get: { store.state.selectedPostIndex ?? 0 },
                        set: { newIndex in
                            withAnimation {
                                store.send(.selectPostByIndex(newIndex))
                            }
                        }
                    )) {
                        ForEach(Array(store.state.sortedPosts.enumerated()), id: \.element.id) { index, post in
                            MapPostCardView(post: post)
                                .tag(index)
                                .padding(.top, 10)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 180)
                }
                .allowsHitTesting(true)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            store.send(.setupLocationManager)
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
    }
}

#Preview {
    MapView()
}
