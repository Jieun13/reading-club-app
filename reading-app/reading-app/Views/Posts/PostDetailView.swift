//
//  PostDetailView.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import SwiftUI
import Combine

struct PostDetailView: View {
    let post: Post
    @State private var comments: [Comment] = []
    @State private var newComment = ""
    @State private var replyingTo: Comment?
    @State private var replyText = ""
    @State private var cancellables = Set<AnyCancellable>()
    @State private var isLoading = false
    @State private var showWishlistSuccessAlert = false
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 게시글 헤더
                VStack(alignment: .leading, spacing: 12) {
                    // 책 정보
                    HStack(spacing: 12) {
                        BookCoverImage(imageUrl: post.bookInfo.cover, width: 80, height: 120, cornerRadius: 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(post.bookInfo.title)
                                .font(.system(size: 16, weight: .bold))
                                .lineLimit(2)
                            
                            Text(post.bookInfo.author)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 8) {
                                PostTypeTag(post: post, fontSize: 11)
                                
                                Spacer()
                                
                                Button(action: {
                                    addToWishlist()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "bookmark")
                                            .font(.system(size: 13))
                                        Text("위시리스트에 추가")
                                            .font(.system(size: 13, weight: .medium))
                                    }
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(6)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                    
                    // 작성자 정보
                    HStack(spacing: 10) {
                        NavigationLink(destination: UserProfileView(userId: post.userId)) {
                            HStack(spacing: 8) {
                                ProfileImage(imageUrl: post.userProfileImage, size: 32)
                                
                                Text(post.userName)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Text(formatDate(post.createdAt))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                // 게시글 내용
                VStack(alignment: .leading, spacing: 16) {
                    if let title = post.title {
                        Text(title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.bottom, 4)
                    }
                    
                    if let content = post.content {
                        Text(content)
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                            .lineSpacing(6)
                            .padding(.vertical, 8)
                    } else if let reason = post.reason {
                        Text(reason)
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                            .lineSpacing(6)
                            .padding(.vertical, 8)
                    } else if let quotes = post.quotes {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(quotes.enumerated()), id: \.offset) { index, quote in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("\"\(quote.text)\"")
                                        .font(.system(size: 15).italic())
                                        .foregroundColor(.primary)
                                        .lineSpacing(6)
                                    Text("p.\(quote.page)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                
                Divider()
                    .padding(.horizontal, 16)
                
                // 댓글 섹션
                VStack(alignment: .leading, spacing: 20) {
                    // 댓글 헤더
                    HStack {
                        Text("댓글")
                            .font(.system(size: 16, weight: .semibold))
                        Text("\(comments.count)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    // 댓글 목록
                    if comments.isEmpty {
                        EmptyStateView(icon: "bubble.left", message: "아직 댓글이 없습니다", iconSize: 28, fontSize: 12)
                            .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(comments) { comment in
                                CommentRow(comment: comment, isReply: false) {
                                    replyingTo = comment
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                
                                if comment.id != comments.last?.id {
                                    Divider()
                                        .padding(.leading, 16)
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                    }
                    
                    // 댓글 작성
                    VStack(alignment: .leading, spacing: 8) {
                        if let replying = replyingTo {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.turn.down.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(.blue)
                                Text("\(replying.user.nickname)에게 답글")
                                    .font(.system(size: 11))
                                    .foregroundColor(.blue)
                                Spacer()
                                Button(action: {
                                    replyingTo = nil
                                    replyText = ""
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.08))
                            .cornerRadius(6)
                        }
                        
                        HStack(alignment: .bottom, spacing: 8) {
                            TextField("댓글을 입력하세요", text: replyingTo != nil ? $replyText : $newComment, axis: .vertical)
                                .lineLimit(2...4)
                                .textFieldStyle(.roundedBorder)
                            
                            Button(action: {
                                if replyingTo != nil {
                                    addReply()
                                } else {
                                    addComment()
                                }
                            }) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background((replyingTo != nil ? !replyText.isEmpty : !newComment.isEmpty) ? Color.blue : Color.gray.opacity(0.3))
                                    .cornerRadius(16)
                            }
                            .disabled(replyingTo != nil ? replyText.isEmpty : newComment.isEmpty)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 16)
            }
            .padding(.bottom, 20)
        }
        .simultaneousGesture(
            TapGesture().onEnded { _ in
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        )
        .navigationTitle("게시글")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadComments()
        }
        .alert("알림", isPresented: $showWishlistSuccessAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("위시리스트에 추가되었습니다.")
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if post.userId == authService.currentUser?.id {
                    Menu {
                        NavigationLink(destination: EditPostView(post: post)) {
                            Label("수정", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: {
                            deletePost()
                        }) {
                            Label("삭제", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
        }
    }
    
    private func loadComments() {
        isLoading = true
        CommentService.shared.getComments(postId: post.id, page: 0, size: 100)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure = completion {
                        // 에러 처리
                    }
                },
                receiveValue: { response in
                    comments = response.comments.content
                }
            )
            .store(in: &cancellables)
    }
    
    private func addComment() {
        guard !newComment.isEmpty else { return }
        isLoading = true
        
        let request = CommentCreateRequest(content: newComment, parentId: nil)
        CommentService.shared.createComment(postId: post.id, request: request)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure = completion {
                        // 에러 처리
                    } else {
                        newComment = ""
                        loadComments()
                    }
                },
                receiveValue: { _ in
                    loadComments()
                }
            )
            .store(in: &cancellables)
    }
    
    private func addReply() {
        guard !replyText.isEmpty, let parent = replyingTo else { return }
        isLoading = true
        
        let request = CommentCreateRequest(content: replyText, parentId: parent.id)
        CommentService.shared.createComment(postId: post.id, request: request)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure = completion {
                        // 에러 처리
                    } else {
                        replyText = ""
                        replyingTo = nil
                        loadComments()
                    }
                },
                receiveValue: { _ in
                    loadComments()
                }
            )
            .store(in: &cancellables)
    }
    
    private func addToWishlist() {
        isLoading = true
        
        let request = WishlistCreateRequest(
            title: post.bookInfo.title,
            author: post.bookInfo.author,
            coverImage: post.bookInfo.cover,
            publisher: post.bookInfo.publisher,
            publishedDate: post.bookInfo.pubDate,
            description: post.bookInfo.description,
            memo: "\(post.userName)님의 게시글에서 추가"
        )
        
        WishlistService.shared.addWishlist(request)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure = completion {
                        // 에러 처리
                    } else {
                        showWishlistSuccessAlert = true
                    }
                },
                receiveValue: { _ in
                    showWishlistSuccessAlert = true
                }
            )
            .store(in: &cancellables)
    }
    
    private func deletePost() {
        PostService.shared.deletePost(id: post.id)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        // 에러 처리
                    } else {
                        dismiss()
                    }
                },
                receiveValue: { _ in
                    dismiss()
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
    NavigationStack {
        PostDetailView(post: Post(
            id: 1,
            userId: 1,
            userName: "테스트 유저",
            userProfileImage: nil,
            postType: .review,
            visibility: "PUBLIC",
            bookInfo: BookInfo(
                isbn: "1234567890",
                title: "테스트 책",
                author: "테스트 저자",
                publisher: "테스트 출판사",
                cover: "",
                pubDate: "2024-01-01",
                description: nil
            ),
            createdAt: "",
            updatedAt: "",
            commentCount: 0,
            title: "테스트 제목",
            content: "테스트 게시글 내용입니다.",
            recommendationType: nil,
            reason: nil,
            quotes: nil,
            quote: nil,
            pageNumber: nil
        ))
        .environmentObject(AuthService.shared)
    }
}

