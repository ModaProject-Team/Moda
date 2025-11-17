//
//  ProfileDetailView.swift
//  Moda
//
//  Created by hyunMac on 11/17/25.
//

import SwiftUI
import Observation

// MARK: - Model
private enum ProfileTab: String, CaseIterable, Identifiable {
    case myItems
    case likeItems

    var id: Self { self }

    var title: String {
        switch self {
        case .myItems: return "내물건"
        case .likeItems: return "찜한목록"
        }
    }
}

// MARK: - State
private struct ProfileDetailState {
    // 입력/환경
    var isCurrentUser: Bool = true

    // 화면 상태
    var nickname: String = "나의 닉네임"
    var selectedTab: ProfileTab = .myItems

    // 데이터
    // MARK: 지금은 프로필 디테일 뷰 목 데이터로 보여주기
    var myItems: [PostCard] = PostCard.mockData
    var likedItems: [PostCard] = Array(PostCard.mockData.prefix(3))

    // 편의
    var currentList: [PostCard] {
        selectedTab == .myItems ? myItems : likedItems
    }
}

// MARK: - Intent
private enum ProfileDetailIntent {
    case onAppear
    case selectTab(ProfileTab)
    case editTapped
    case uploadTapped
}

// MARK: - Store (@Observable)
@MainActor
@Observable
private final class ProfileDetailStore {

    var state = ProfileDetailState()

    func send(_ intent: ProfileDetailIntent) {
        switch intent {
        case .onAppear:
            handleOnAppear()
        case .selectTab(let tab):
            handleSelectTab(tab)
        case .editTapped:
            handleEditTapped()
        case .uploadTapped:
            handleUploadTapped()
        }
    }

    // MARK: - Handlers
    private func handleOnAppear() {
        if state.isCurrentUser == false {
            state.nickname = "친구 닉네임"
        } else {
            state.nickname = "나의 닉네임"
        }
    }

    private func handleSelectTab(_ tab: ProfileTab) {
        state.selectedTab = tab
    }

    private func handleEditTapped() {
        print("수정 버튼 탭")
    }

    private func handleUploadTapped() {
        print("물건 올리기 버튼 탭")
    }
}

// MARK: - View
struct ProfileDetailView: View {
    @State private var store = ProfileDetailStore()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            content
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                }
            }
            if store.state.isCurrentUser {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("수정") {
                        store.send(.editTapped)
                    }
                    .font(.body.weight(.semibold))
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if store.state.isCurrentUser {
                FloatingUploadButton(title: "물건 올리기") {
                    store.send(.uploadTapped)
                }
                .padding(.trailing, 16)
                .padding(.bottom, 24)
            }
        }
        .task { store.send(.onAppear) }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 16) {
                header

                if store.state.isCurrentUser {
                    segment
                }

                productGrid
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 80) // 플로팅 버튼 영역 확보
        }
        .scrollIndicators(.hidden)
    }

    private var header: some View {
        VStack(spacing: 10) {
            // 아바타 플레이스홀더
            ZStack {
                Circle().fill(Color.gray.opacity(0.2))
                Image(systemName: "person.fill")
                    .foregroundStyle(.secondary)
            }
            .frame(width: 72, height: 72)

            Text(store.state.nickname)
                .font(.headline.weight(.semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var segment: some View {
        Picker("", selection: Binding(
            get: { store.state.selectedTab },
            set: { store.send(.selectTab($0)) }
        )) {
            ForEach(ProfileTab.allCases) { tab in
                Text(tab.title).tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - 물건 아이템을 목데이터로 보여주기 임시 뷰, 수정 필요
    private var productGrid: some View {
        let items: [PostCard] = store.state.isCurrentUser
            ? (store.state.selectedTab == .myItems ? store.state.myItems : store.state.likedItems)
            : store.state.myItems

        return VStack(alignment: .leading, spacing: 12) {
            if items.isEmpty {
                Text(store.state.isCurrentUser && store.state.selectedTab == .likeItems ? "찜한 물건이 없어요" : "등록된 물건이 없어요")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                HStack(alignment: .top, spacing: 12) {
                    // 좌/우 컬럼으로 간단한 masonry
                    LazyVStack(spacing: 12) {
                        ForEach(Array(items.enumerated()).filter { $0.offset % 2 == 0 }, id: \.element.id) { _, product in
                            PostCardView(product: product, store: FeedViewStore())
                        }
                    }
                    LazyVStack(spacing: 12) {
                        ForEach(Array(items.enumerated()).filter { $0.offset % 2 == 1 }, id: \.element.id) { _, product in
                            PostCardView(product: product, store: FeedViewStore())
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Subviews
private struct FloatingUploadButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.orange)
                )
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    NavigationStack {
        VStack(spacing: 12) {
            ProfileDetailView()
                .navigationTitle("프로필")
        }
    }
}
