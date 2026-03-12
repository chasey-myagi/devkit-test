import SwiftUI

/// 评论列表组件
struct CommentListView: View {
    let comments: [GHComment]
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(DKSpacing.xl)
            } else if comments.isEmpty {
                Text("No comments")
                    .font(DKTypography.body())
                    .foregroundStyle(DKColor.Foreground.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(DKSpacing.xl)
            } else {
                let lastID = comments.last?.id
                ForEach(comments) { comment in
                    VStack(alignment: .leading, spacing: DKSpacing.xs) {
                        HStack {
                            Text(comment.author.login)
                                .font(DKTypography.caption())
                                .fontWeight(.semibold)
                                .foregroundStyle(DKColor.Foreground.primary)
                            Spacer()
                            if let date = comment.createdDate {
                                Text(date, style: .relative)
                                    .font(DKTypography.captionSmall())
                                    .foregroundStyle(DKColor.Foreground.tertiary)
                            } else {
                                Text(comment.createdAt)
                                    .font(DKTypography.captionSmall())
                                    .foregroundStyle(DKColor.Foreground.tertiary)
                            }
                        }
                        // 尝试 Markdown 渲染，失败则显示纯文本
                        if let attributed = try? AttributedString(markdown: comment.body) {
                            Text(attributed)
                                .font(DKTypography.body())
                                .foregroundStyle(DKColor.Foreground.primary)
                        } else {
                            Text(comment.body)
                                .font(DKTypography.body())
                                .foregroundStyle(DKColor.Foreground.primary)
                        }
                    }
                    .padding(.vertical, DKSpacing.sm)
                    if comment.id != lastID {
                        Divider()
                    }
                }
            }
        }
    }
}

/// 评论输入组件
struct CommentInputView: View {
    @Binding var text: String
    let isPosting: Bool
    let onPost: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: DKSpacing.sm) {
            TextEditor(text: $text)
                .font(DKTypography.body())
                .frame(minHeight: 36, maxHeight: 100)
                .scrollContentBackground(.hidden)
                .padding(DKSpacing.sm)
                .background(DKColor.Surface.secondary)
                .clipShape(RoundedRectangle(cornerRadius: DKRadius.sm))

            Button {
                onPost()
            } label: {
                if isPosting {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "paperplane.fill")
                }
            }
            .buttonStyle(DKPrimaryButtonStyle())
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isPosting)
        }
    }
}
