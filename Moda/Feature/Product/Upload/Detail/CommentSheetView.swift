//
//  CommentSheetView.swift
//  Moda
//
//  Created by 금가경 on 11/28/25.
//

import SwiftUI
import Kingfisher

struct CommentSheetView: View {
    let postId: String
    @StateObject private var store: CommentStore
    @Environment(\.dismiss) var dismiss

    init(postId: String) {
        self.postId = postId
        self._store = StateObject(wrappedValue: CommentStore(postId: postId))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if store.state.isLoading && store.state.comments.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if store.state.comments.isEmpty {
                    emptyView
                } else {
                    commentList
                }

                Divider()

                inputSection
            }
            .navigationTitle("댓글")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.gray1)
                    }
                }
            }
        }
        .task {
            store.send(.loadComments)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left")
                .font(.system(size: 60))
                .foregroundColor(.gray3)
            Text("첫 댓글을 남겨보세요")
                .Body1()
                .foregroundColor(.gray2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var commentList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(store.state.comments, id: \.commentId) { comment in
                    CommentRow(
                        comment: comment,
                        onReply: { commentId in
                            store.send(.startReply(commentId: commentId))
                        },
                        onDelete: { commentId in
                            store.send(.deleteComment(commentId: commentId))
                        }
                    )

                    if let replies = comment.replies, !replies.isEmpty {
                        ForEach(replies, id: \.commentId) { reply in
                            ReplyRow(
                                reply: reply,
                                onDelete: { replyId in
                                    store.send(.deleteReply(commentId: comment.commentId, replyId: replyId))
                                }
                            )
                        }
                    }

                    Divider()
                        .padding(.leading, 16)
                }
            }
            .padding(.bottom, 100)
        }
    }

    private var inputSection: some View {
        VStack(spacing: 0) {
            if store.state.replyingToCommentId != nil {
                HStack {
                    Text("답글 작성 중")
                        .Body2()
                        .foregroundColor(.blue1)
                    Spacer()
                    Button {
                        store.send(.cancelReply)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray2)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.gray5)
            }

            HStack(spacing: 12) {
                TextField("댓글을 입력하세요", text: Binding(
                    get: { store.state.inputText },
                    set: { store.send(.updateInputText($0)) }
                ))
                .Input()
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray5)
                )

                Button {
                    store.send(.sendComment)
                } label: {
                    ZStack {
                        Circle()
                            .fill(store.state.inputText.isEmpty ? Color.gray3 : Color.blue1)
                            .frame(width: 36, height: 36)

                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .disabled(store.state.inputText.isEmpty || store.state.isSending)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
        }
    }
}

struct CommentRow: View {
    let comment: Comment
    let onReply: (String) -> Void
    let onDelete: (String) -> Void
    @State private var showDeleteAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                if let profileImage = comment.creator.profileImage, !profileImage.isEmpty {
                    KFImage(URL(string: "\(NetworkConfig.baseURL)/v1\(profileImage)"))
                        .requestModifier(KFHeaders.modifier)
                        .placeholder {
                            Circle()
                                .fill(Color.gray3)
                                .overlay {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.gray2)
                                }
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray3)
                        .frame(width: 36, height: 36)
                        .overlay {
                            Image(systemName: "person.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.gray2)
                        }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(comment.creator.nickname)
                            .Body2()
                            .foregroundColor(.gray1)
                            .fontWeight(.semibold)

                        Text(comment.createdAt.toRelativeTimeString())
                            .Body2()
                            .foregroundColor(.gray2)

                        Spacer()

                        Button("답글", systemImage: "arrowshape.turn.up.left") {
                            onReply(comment.commentId)
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.gray2)

                        Button {
                            showDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundColor(.gray2)
                        }
                    }

                    Text(comment.content)
                        .Body1()
                        .foregroundColor(.gray1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .alert("댓글 삭제", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                onDelete(comment.commentId)
            }
        } message: {
            Text("이 댓글을 삭제하시겠습니까?")
        }
    }

}

struct ReplyRow: View {
    let reply: Reply
    let onDelete: (String) -> Void
    @State private var showDeleteAlert = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "arrow.turn.down.right")
                .font(.system(size: 14))
                .foregroundColor(.gray2)
                .padding(.leading, 16)

            if let profileImage = reply.creator.profileImage, !profileImage.isEmpty {
                KFImage(URL(string: "\(NetworkConfig.baseURL)/v1\(profileImage)"))
                    .requestModifier(KFHeaders.modifier)
                    .placeholder {
                        Circle()
                            .fill(Color.gray3)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray2)
                            }
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray3)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray2)
                    }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(reply.creator.nickname)
                        .Body2()
                        .foregroundColor(.gray1)
                        .fontWeight(.semibold)

                    Text(reply.createdAt.toRelativeTimeString())
                        .Body2()
                        .foregroundColor(.gray2)

                    Spacer()

                    Button {
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.gray2)
                    }
                }

                Text(reply.content)
                    .Body1()
                    .foregroundColor(.gray1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .alert("답글 삭제", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                onDelete(reply.commentId)
            }
        } message: {
            Text("이 답글을 삭제하시겠습니까?")
        }
    }

}

struct CommentState {
    var comments: [Comment] = []
    var inputText: String = ""
    var replyingToCommentId: String?
    var isLoading: Bool = false
    var isSending: Bool = false
    var errorMessage: String?
}

enum CommentIntent {
    case loadComments
    case updateInputText(String)
    case sendComment
    case startReply(commentId: String)
    case cancelReply
    case deleteComment(commentId: String)
    case deleteReply(commentId: String, replyId: String)
}

@MainActor
final class CommentStore: ObservableObject {
    @Published private(set) var state = CommentState()

    private let postId: String
    private let commentAPI: CommentAPIProtocol

    init(postId: String, commentAPI: CommentAPIProtocol = CommentAPI.shared) {
        self.postId = postId
        self.commentAPI = commentAPI
    }

    func send(_ intent: CommentIntent) {
        switch intent {
        case .loadComments:
            Task { await loadComments() }

        case .updateInputText(let text):
            state.inputText = text

        case .sendComment:
            Task { await sendComment() }

        case .startReply(let commentId):
            state.replyingToCommentId = commentId

        case .cancelReply:
            state.replyingToCommentId = nil

        case .deleteComment(let commentId):
            Task { await deleteComment(commentId: commentId) }

        case .deleteReply(let commentId, let replyId):
            Task { await deleteReply(commentId: commentId, replyId: replyId) }
        }
    }

    private func loadComments() async {
        state.isLoading = true

        do {
            let response = try await commentAPI.getComments(postId: postId)
            state.comments = response.toDomain()
            state.isLoading = false
        } catch {
            state.errorMessage = "댓글을 불러오는데 실패했습니다"
            state.isLoading = false
        }
    }

    private func sendComment() async {
        guard !state.inputText.isEmpty else { return }

        state.isSending = true
        let content = state.inputText

        do {
            if let replyingTo = state.replyingToCommentId {
                _ = try await commentAPI.createReply(postId: postId, commentId: replyingTo, content: content)
                state.replyingToCommentId = nil
            } else {
                _ = try await commentAPI.createComment(postId: postId, content: content)
            }

            state.inputText = ""
            state.isSending = false
            await loadComments()
            NotificationCenter.default.post(name: NSNotification.Name("commentUpdated"), object: nil)
        } catch {
            state.errorMessage = "댓글 작성에 실패했습니다"
            state.isSending = false
        }
    }

    private func deleteComment(commentId: String) async {
        do {
            try await commentAPI.deleteComment(postId: postId, commentId: commentId)
            await loadComments()
            NotificationCenter.default.post(name: NSNotification.Name("commentUpdated"), object: nil)
        } catch {
            state.errorMessage = "댓글 삭제에 실패했습니다"
        }
    }

    private func deleteReply(commentId: String, replyId: String) async {
        do {
            try await commentAPI.deleteComment(postId: postId, commentId: replyId)
            await loadComments()
            NotificationCenter.default.post(name: NSNotification.Name("commentUpdated"), object: nil)
        } catch {
            state.errorMessage = "답글 삭제에 실패했습니다"
        }
    }
}

#Preview {
    CommentSheetView(postId: "test")
}
