//
//  MainTabView.swift
//  Moda
//
//  Created by 금가경 on 11/16/25.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var store = MainTabViewStore()
    @EnvironmentObject var navigator: AppNavigator

    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent

            CustomTabBar(
                selectedTab: store.state.selectedTab,
                onTabSelected: { tab in
                    store.send(.tabSelected(tab))
                }
            )
            .edgesIgnoringSafeArea(.bottom)
        }
        .ignoresSafeArea(.keyboard)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch store.state.selectedTab {
        case .home:
            FeedView()
        case .map:
            MapView()
        case .friends:
            FriendListView()
        case .chat:
            ChatListView()
        case .setting:
            SettingView()
        }
    }
}

struct CustomTabBar: View {
    let selectedTab: TabItem
    let onTabSelected: (TabItem) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.vertical, 12)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: -2)
    }

    private func tabButton(for tab: TabItem) -> some View {
        Button {
            onTabSelected(tab)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 20))
                    .foregroundColor(selectedTab == tab ? .gray1 : .gray1.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
    }
}

struct PlaceholderView: View {
    let title: String

    var body: some View {
        VStack {
            Text(title)
                .H1()
                .foregroundColor(.gray1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppNavigator.shared)
}
