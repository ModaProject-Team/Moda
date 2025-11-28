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
    @EnvironmentObject var navigator: AppNavigator

    var body: some View {
        ZStack {
            Map(position: Binding(
                get: { store.state.cameraPosition },
                set: { store.send(.updateCameraPosition($0)) }
            )) {
                UserAnnotation()

                ForEach(store.state.mapItems) { item in
                    switch item {
                    case .single(let post):
                        Annotation("", coordinate: post.coordinate) {
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

                    case .cluster(let posts):
                        let clusterPostIds = Set(posts.map { $0.id })
                        let isClusterSelected = store.state.selectedClusterPostIds == clusterPostIds

                        Annotation("", coordinate: item.coordinate) {
                            ClusterAnnotationView(
                                count: posts.count,
                                representativeImage: posts.first?.media ?? "",
                                isSelected: isClusterSelected
                            )
                            .onTapGesture {
                                withAnimation {
                                    // 클러스터 탭 시 해당 위치로 카메라 이동 (현재 줌 레벨 유지)
                                    let region = MKCoordinateRegion(
                                        center: item.coordinate,
                                        span: store.state.currentSpan
                                    )
                                    store.send(.updateCameraPosition(.region(region)))
                                    store.send(.selectCluster(clusterPostIds))
                                }
                                
                                store.send(.showClusterSheet(posts))
                                
                            }
                        }
                    }
                }
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                store.send(.updateSpan(context.region.span))
                store.send(.mapDidMove(context.region.center))
            }
            .mapControls { }  // 기본 UI 전부 숨기고 커스텀 모드로 전환
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        // 카드가 열려있거나 클러스터 시트가 열려있을 때 지도 배경 탭으로 닫기
                        if store.state.selectedPostIndex != nil {
                            store.send(.selectPost(nil))
                        }
                        if store.state.showClusterSheet {
                            store.send(.dismissClusterSheet)
                        }
                    }
            )
            .ignoresSafeArea()

            // 상단 중앙 - 현 지도에서 검색 버튼
            VStack {
                if store.state.showSearchButton {
                    Button {
                        store.send(.searchInCurrentMap)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14))
                            Text("현 지도에서 검색")
                                .Body2()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.blue1)
                        .clipShape(Capsule())
                    }
                    .frame(height: 44)
                    .padding(.top, 16)
                }

                Spacer()
            }

            // 우측 상단 - 현재 위치 버튼
            VStack {
                HStack {
                    Spacer()

                    Button {
                        withAnimation {
                            store.send(.moveToUserLocation)
                        }
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.blue1)
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 16)
                .padding(.trailing, 16)

                Spacer()
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
                            MapPostCardView(
                                post: post,
                                onLikeTapped: { postId, isLiked in
                                    store.send(.toggleLike(postId: postId, isLiked: isLiked))
                                },
                                onTapped: {
                                    navigator.push(.productDetail(postId: post.id))
                                }
                            )
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
        .sheet(isPresented: Binding(
            get: { store.state.showClusterSheet },
            set: { if !$0 { store.send(.dismissClusterSheet) } }
        )) {
            ClusterSheetView(
                posts: store.state.clusterSheetPosts,
                onDismiss: {
                    store.send(.dismissClusterSheet)
                },
                onLikeTapped: { postId, isLiked in
                    store.send(.toggleLike(postId: postId, isLiked: isLiked))
                },
                onPostTapped: { postId in
                    store.send(.dismissClusterSheet)
                    navigator.push(.productDetail(postId: postId))
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .postLikeUpdated)) { notification in
            if let userInfo = notification.userInfo,
               let postId = userInfo["postId"] as? String,
               let isLiked = userInfo["isLiked"] as? Bool {
                store.send(.updateLikeFromExternal(postId: postId, isLiked: isLiked))
            }
        }
    }
}

#Preview {
    MapView()
}
