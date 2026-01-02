//
//  PostCard.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import SwiftUI

struct PostCard: View {
    let post: Post
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // 왼쪽: 책 정보 (회색 배경) - 40%
                VStack(alignment: .leading, spacing: 8) {
                    // 책 표지
                    BookCoverImage(imageUrl: post.bookInfo.cover, width: 64, height: 80, cornerRadius: 4)
                    
                    // 책 정보
                    VStack(alignment: .leading, spacing: 4) {
                        Text(post.bookInfo.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(post.bookInfo.author)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                }
                .padding(16)
                .frame(width: geometry.size.width * 0.4)
                .background(Color(.systemGray6))
            
                // 오른쪽: 게시글 정보 - 60%
                VStack(alignment: .leading, spacing: 12) {
                    // 상단: 게시글 타입과 댓글 개수
                    HStack {
                        HStack(spacing: 8) {
                            PostTypeTag(post: post, fontSize: 11)
                            
                            if post.visibility == "PRIVATE" {
                                Text("비공개")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(6)
                            }
                        }
                        
                        Spacer()
                        
                        // 댓글 개수
                        if let commentCount = post.commentCount, commentCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "bubble.right")
                                    .font(.system(size: 12))
                                Text("\(commentCount)")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    // 중간: 게시글 내용
                    Group {
                        if let content = post.content {
                            Text(content)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .lineLimit(5)
                        } else if let reason = post.reason {
                            Text(reason)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .lineLimit(5)
                        } else if let quotes = post.quotes, !quotes.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(Array(quotes.prefix(3).enumerated()), id: \.offset) { index, quote in
                                    Text("\"\(quote.text)\"")
                                        .font(.system(size: 13).italic())
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                if quotes.count > 3 {
                                    Text("+\(quotes.count - 3)개 문장 더보기")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    
                    // 하단: 작성자 정보와 작성일
                    HStack {
                        ProfileImage(imageUrl: post.userProfileImage, size: 20)
                        
                        Text(post.userName)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formatDate(post.createdAt))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.top, 8)
                }
                .padding(16)
                .frame(width: geometry.size.width * 0.6, alignment: .leading)
            }
        }
        .frame(height: 192)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy.MM.dd"
            return displayFormatter.string(from: date)
        }
        // 날짜 파싱 실패 시 원본 문자열에서 날짜 부분만 추출
        if let dateRange = dateString.range(of: #"\d{4}-\d{2}-\d{2}"#, options: .regularExpression) {
            let datePart = String(dateString[dateRange])
            return datePart.replacingOccurrences(of: "-", with: ".")
        }
        return dateString
    }
}

#Preview {
    PostCard(post: Post(
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
        commentCount: 5,
        title: "테스트 제목",
        content: "테스트 게시글 내용입니다.",
        recommendationType: nil,
        reason: nil,
        quotes: nil,
        quote: nil,
        pageNumber: nil
    ))
    .padding()
}

