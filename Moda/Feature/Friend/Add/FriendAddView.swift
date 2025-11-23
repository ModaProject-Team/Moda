//
//  FriendAddView.swift
//  Moda
//
//  Created by hyunMac on 11/16/25.
//

import SwiftUI
import Observation
import Kingfisher

//MARK: 검색 결과 모델
private struct FriendSearchItem: Identifiable, Hashable {
    let id: String          // userId
    let nickname: String    // nick
    let profileImageURL: URL?
}

// MARK: - State
private struct FriendAddState {
    var query: String = ""
    let maxLength: Int = 20

    // 검색 관련 상태
    var results: [FriendSearchItem] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var hasSearched: Bool = false // 첫 검색 여부

    // 선택된 셀(선택 시 목록 숨기고 카드만 노출)
    var selectedItem: FriendSearchItem?

    // 선택된 항목의 "친구 여부"(추후 네트워크로 설정, 초기 nil이면 '친구 추가'로 노출)
    var selectedIsFriend: Bool?
}


// MARK: - Intent
private enum FriendAddIntent {
    case onAppear
    case queryChanged(String)
    case clearTapped
    case searchSubmitted
    case rowTapped(FriendSearchItem)

    // 카드 친구 추가 버튼 탭
    case friendAddButtonTapped

    // 카드 닫기(X) 버튼 탭
    case cardCloseTapped
}

// MARK: - Store (@Observable)
@MainActor
@Observable
private final class FriendAddStore {
    var state = FriendAddState()

    // 의존성
    private let userAPI = UserAPI.shared
    private let userProfileAPI: UserProfileAPIProtocol = UserProfileAPI.shared

    // 동시 검색 취소용
    private var searchTask: Task<Void, Never>?

    // 내 사용자 ID
    private var myUserId: String?

    func send(_ intent: FriendAddIntent) {
        switch intent {
        case .onAppear:
            handleOnAppear()
        case .queryChanged(let text):
            handleQueryChanged(text)
        case .clearTapped:
            state.query = ""
        case .searchSubmitted:
            handleSearchSubmitted()
        case .rowTapped(let item):
            handleRowTapped(item)
        case .friendAddButtonTapped:
            handlefriendAddButtonTapped()
        case .cardCloseTapped:
            handleCardCloseTapped()
        }
    }

    // MARK: - Handlers
    private func handleOnAppear() {
        // 최초 1회 내 프로필 로드
        guard myUserId == nil else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                let me = try await userProfileAPI.getMyProfile()
                self.myUserId = me.userId
            } catch {
                print("친구 추가 뷰,내 프로필 불러오지 못함", error.localizedDescription)
            }
        }
    }

    private func handleQueryChanged(_ text: String) {
        // 입력 중 최대길이 도달시 입력 방지
        state.query = clampToMaxLength(text)
    }

    private func handleSearchSubmitted() {
        // 필요 시 공백 제거 + 길이 보정
        let trimmed = state.query.trimmingCharacters(in: .whitespacesAndNewlines)
        state.query = clampToMaxLength(trimmed)

        // 빈 입력은 무시
        guard !state.query.isEmpty else { return }

        // 첫 검색 실행 표시
        state.hasSearched = true

        // 이전 검색 취소
        searchTask?.cancel()

        // 선택 상태 초기화(새 검색 시작 시 카드 숨김)
        state.selectedItem = nil
        state.selectedIsFriend = nil

        // 로딩 시작
        state.isLoading = true
        state.errorMessage = nil
        state.results = []

        let query = state.query

        // 실제 네트워크 검색
        searchTask = Task { [weak self] in
            guard let self else { return }
            do {
                let response = try await userAPI.searchUsers(query: query)

                // 취소되었으면 중단
                if Task.isCancelled { return }

                var items: [FriendSearchItem] = response.data.map { dto in
                    FriendSearchItem(
                        id: dto.userId,
                        nickname: dto.nick,
                        profileImageURL: URL(string: "\(NetworkConfig.baseURL)/v1\(dto.profileImage ?? "")")
                    )
                }

                // 내 아이디 제외
                if let myId = self.myUserId {
                    items.removeAll { $0.id == myId }
                }

                state.results = items
            } catch {
                if let netErr = error as? NetworkError {
                    state.errorMessage = netErr.localizedDescription
                } else {
                    state.errorMessage = error.localizedDescription
                }
            }
            state.isLoading = false
        }
    }

    private func handleRowTapped(_ item: FriendSearchItem) {
        // 선택된 셀로 카드 표시
        state.selectedItem = item

        // TODO: 여기서 서버에 해당 유저의 친구 여부 조회 요청
        state.selectedIsFriend = nil // 아직 모르는 상태(nil) → 버튼은 "친구 추가"로 노출
    }

    private func handlefriendAddButtonTapped() {
        print("친구 추가 버튼 눌림")
    }

    private func handleCardCloseTapped() {
        // 카드 닫기: 선택 해제 → 기존 검색 결과 리스트 노출
        state.selectedItem = nil
        state.selectedIsFriend = nil
    }

    // MARK: - Helpers
    private func clampToMaxLength(_ text: String) -> String {
        if text.count > state.maxLength {
            return String(text.prefix(state.maxLength))
        } else {
            return text
        }
    }
}

// MARK: - View
struct FriendAddView: View {
    @State private var store = FriendAddStore()
    @FocusState private var isSearching: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            FriendIDSearchBar(
                text: Binding(
                    get: { store.state.query },
                    set: { store.send(.queryChanged($0)) }
                ),
                isFocused: _isSearching,
                maxLength: store.state.maxLength,
                onSubmit: {
                    // 키보드의 Search 버튼을 눌렀을 때만 검색
                    store.send(.searchSubmitted)
                    isSearching = false
                }, onClear: {
                    store.send(.clearTapped)
                }
            )

            // 선택된 카드가 있으면 카드만 노출, 아니면 기존 결과 영역
            if let selected = store.state.selectedItem {
                FriendSelectedCard(
                    item: selected,
                    buttonTitle: (store.state.selectedIsFriend == true) ? "친구 취소" : "친구 추가",
                    onButtonTap: {
                        store.send(.friendAddButtonTapped)
                    },
                    onCloseTap: {
                        store.send(.cardCloseTapped)
                    }
                )
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .frame(maxWidth: .infinity, maxHeight: 320, alignment: .top)

                Spacer()
            } else {
                // 결과 영역
                Group {
                    if store.state.isLoading {
                        ProgressView("검색 중…")
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    } else if let message = store.state.errorMessage {
                        ContentUnavailableView(
                            "오류가 발생했어요",
                            systemImage: "exclamationmark.triangle",
                            description: Text(message)
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if !store.state.hasSearched {
                        // 초기 상태(중립 안내): 아직 검색하지 않았을 때
                        ContentUnavailableView(
                            "친구를 검색해 보세요",
                            systemImage: "person.crop.circle.badge.magnifyingglass",
                            description: Text("닉네임을 입력하고 검색을 눌러보세요.")
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if store.state.results.isEmpty {
                        // 검색은 했지만 결과가 없을 때
                        ContentUnavailableView(
                            "검색 결과가 없어요",
                            systemImage: "person.fill.questionmark",
                            description: Text("다른 닉네임으로 다시 시도해 보세요.")
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(store.state.results) { item in
                            Button {
                                store.send(.rowTapped(item))
                                isSearching = false
                            } label: {
                                FriendRow(item: item)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle("닉네임으로 추가")
        .toolbarTitleDisplayMode(.inline)
        .task {
            // 진입 시 내 ID 로드 + 키보드 포커스
            store.send(.onAppear)
            try? await Task.sleep(for: .milliseconds(250))
            await MainActor.run {
                isSearching = true
            }
        }
    }
}

// MARK: - Search Bar
private struct FriendIDSearchBar: View {
    @Binding var text: String
    @FocusState var isFocused: Bool
    let maxLength: Int
    let onSubmit: () -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                TextField("닉네임", text: $text)
                    .textInputAutocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($isFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        onSubmit()
                    }

                Text("\(text.count)/\(maxLength)")
                    .monospacedDigit()
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            // 언더라인
            Rectangle()
                .fill(Color.primary.opacity(0.2))
                .frame(height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
}

// MARK: - 친구 선택 카드
private struct FriendSelectedCard: View {
    let item: FriendSearchItem
    let buttonTitle: String
    let onButtonTap: () -> Void
    let onCloseTap: () -> Void

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(uiColor: .secondarySystemBackground))
            .overlay(
                VStack(spacing: 14) {
                    // 프로필 이미지
                    ProfileImageView(url: item.profileImageURL)
                        .frame(width: 72, height: 72)

                    VStack(spacing: 4) {
                        Text(item.nickname)
                            .font(.headline)
                        Text("ID: \(item.id)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        // View는 로직을 갖지 않고 Intent만 보냄
                        onButtonTap()
                    } label: {
                        Text(buttonTitle)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: 140)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.orange)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 12)
            )
            // 카드 우상단 X 버튼
            .overlay(alignment: .topTrailing) {
                Button {
                    onCloseTap()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(
                            Circle().fill(Color.black.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
                .padding(8) // 카드 모서리와 간격
            }
    }
}

// MARK: - Result Row
private struct FriendRow: View {
    let item: FriendSearchItem

    var body: some View {
        HStack(spacing: 12) {
            ProfileImageView(url: item.profileImageURL)
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.nickname)
                    .font(.body.weight(.semibold))
                Text(item.id)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Image View (Kingfisher + KFHeaders)
private struct ProfileImageView: View {
    let url: URL?

    var body: some View {
        if let url {
            KFImage(url)
                .requestModifier(KFHeaders.modifier) // 인증/공통 헤더
                .placeholder { placeholder }
                .cacheOriginalImage()
                .fade(duration: 0.2)
                .cancelOnDisappear(true)
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            Circle().fill(Color.gray.opacity(0.2))
            Image(systemName: "person.fill")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        FriendAddView()
    }
}
