//
//  CommentSheetView.swift
//  Moda
//
//  Created by 금가경 on 11/28/25.
//

import SwiftUI

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
        .onTapGesture {
            hideKeyboard()
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
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    hideKeyboard()
                }
        )
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

    private var isMyComment: Bool {
        guard let currentUserId = UserDefaultsManager.shared.userId else { return false }
        return comment.creator.userId == currentUserId
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                if let profileImage = comment.creator.profileImage, !profileImage.isEmpty {
                    CachedImageView(
                        url: URL(string: "\(NetworkConfig.baseURL)/v1\(profileImage)"),
                        targetSize: CGSize(width: 36, height: 36),
                        contentMode: .fill,
                        placeholder: {
                            AnyView(
                                Circle()
                                    .fill(Color.gray3)
                                    .overlay {
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.gray2)
                                    }
                            )
                        }
                    )
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

                        Button {
                            onReply(comment.commentId)
                        } label: {
                            Image(systemName: "arrowshape.turn.up.left")
                                .font(.system(size: 14))
                                .foregroundColor(.gray2)
                        }

                        if isMyComment {
                            Button {
                                showDeleteAlert = true
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray2)
                            }
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

    private var isMyReply: Bool {
        guard let currentUserId = UserDefaultsManager.shared.userId else { return false }
        return reply.creator.userId == currentUserId
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "arrow.turn.down.right")
                .font(.system(size: 14))
                .foregroundColor(.gray2)
                .padding(.leading, 16)

            if let profileImage = reply.creator.profileImage, !profileImage.isEmpty {
                CachedImageView(
                    url: URL(string: "\(NetworkConfig.baseURL)/v1\(profileImage)"),
                    targetSize: CGSize(width: 32, height: 32),
                    contentMode: .fill,
                    placeholder: {
                        AnyView(
                            Circle()
                                .fill(Color.gray3)
                                .overlay {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.gray2)
                                }
                        )
                    }
                )
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

                    if isMyReply {
                        Button {
                            showDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundColor(.gray2)
                        }
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

#Preview {
    CommentSheetView(postId: "test")
}
