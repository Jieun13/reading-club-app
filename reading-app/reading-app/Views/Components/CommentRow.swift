//
//  CommentRow.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import SwiftUI
import Combine

struct CommentRow: View {
    let comment: Comment
    let onReply: () -> Void
    let isReply: Bool
    @State private var showingReplies = false
    @State private var replies: [Comment] = []
    @State private var cancellables = Set<AnyCancellable>()
    
    init(comment: Comment, isReply: Bool = false, onReply: @escaping () -> Void) {
        self.comment = comment
        self.isReply = isReply
        self.onReply = onReply
    }
    
    var body: some View {
        if isReply {
            HStack(alignment: .top, spacing: 12) {
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(width: 2)
                
                commentContent
            }
        } else {
            commentContent
        }
    }
    
    private var commentContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 헤더 (프로필 + 닉네임 + 날짜)
            HStack(alignment: .center, spacing: 10) {
                NavigationLink(destination: UserProfileView(userId: comment.user.id)) {
                    ProfileImage(imageUrl: comment.user.profileImage, size: 32)
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 2) {
                    NavigationLink(destination: UserProfileView(userId: comment.user.id)) {
                        Text(comment.user.nickname)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    
                    Text(formatDate(comment.createdAt))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // 댓글 내용
            if comment.isDeleted {
                Text("삭제된 댓글입니다.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.vertical, 4)
            } else {
                Text(comment.content)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 4)
            }
            
            // 액션 버튼
            if !comment.isDeleted {
                HStack(spacing: 16) {
                    Button(action: onReply) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.turn.down.right")
                                .font(.system(size: 11))
                            Text("답글")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.blue)
                    }
                    
                    if comment.replyCount > 0 {
                        Button(action: {
                            showingReplies.toggle()
                            if showingReplies && replies.isEmpty && comment.replies == nil {
                                loadReplies()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text("답글 \(comment.replyCount)개")
                                    .font(.system(size: 12))
                                Image(systemName: showingReplies ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
            
            // 답글 목록
            if showingReplies, let commentReplies = comment.replies, !commentReplies.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(commentReplies) { reply in
                        CommentRow(comment: reply, isReply: true, onReply: onReply)
                            .padding(.vertical, 10)
                        
                        if reply.id != commentReplies.last?.id {
                            Divider()
                                .padding(.leading, isReply ? 0 : 20)
                        }
                    }
                }
                .padding(.leading, isReply ? 0 : 20)
                .padding(.top, 12)
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(8)
            } else if showingReplies && !replies.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(replies) { reply in
                        CommentRow(comment: reply, isReply: true, onReply: onReply)
                            .padding(.vertical, 10)
                        
                        if reply.id != replies.last?.id {
                            Divider()
                                .padding(.leading, isReply ? 0 : 20)
                        }
                    }
                }
                .padding(.leading, isReply ? 0 : 20)
                .padding(.top, 12)
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(8)
            }
        }
    }
    
    private func loadReplies() {
        CommentService.shared.getReplies(commentId: comment.id)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { loadedReplies in
                    replies = loadedReplies
                }
            )
            .store(in: &cancellables)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            return displayFormatter.string(from: date)
        }
        // 날짜 파싱 실패 시 원본 문자열에서 날짜 부분만 추출
        if let dateRange = dateString.range(of: #"\d{4}-\d{2}-\d{2}"#, options: .regularExpression),
           let timeRange = dateString.range(of: #"\d{2}:\d{2}"#, options: .regularExpression) {
            let datePart = String(dateString[dateRange])
            let timePart = String(dateString[timeRange])
            return "\(datePart) \(timePart)"
        }
        return dateString
    }
}

#Preview {
    CommentRow(
        comment: Comment(
            id: 1,
            content: "테스트 댓글입니다.",
            isDeleted: false,
            isReply: false,
            parentId: nil,
            replyCount: 2,
            canDelete: true,
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z",
            user: CommentUser(id: 1, nickname: "테스트", profileImage: nil),
            replies: nil
        ),
        onReply: {}
    )
    .padding()
}

