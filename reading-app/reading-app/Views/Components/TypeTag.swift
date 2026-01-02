//
//  TypeTag.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import SwiftUI

struct TypeTag: View {
    let text: String
    let backgroundColor: Color
    let textColor: Color
    let fontSize: CGFloat
    
    init(text: String, color: Color, fontSize: CGFloat = 12) {
        self.text = text
        self.fontSize = fontSize
        // 기존 호환성을 위해 단일 color를 받으면 배경색으로 사용하고 텍스트는 흰색
        self.backgroundColor = color
        self.textColor = .white
    }
    
    init(text: String, backgroundColor: Color, textColor: Color, fontSize: CGFloat = 12) {
        self.text = text
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.fontSize = fontSize
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .medium))
            .foregroundColor(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .cornerRadius(6)
    }
}

struct PostTypeTag: View {
    let post: Post
    let fontSize: CGFloat
    
    init(post: Post, fontSize: CGFloat = 12) {
        self.post = post
        self.fontSize = fontSize
    }
    
    // 기존 호환성을 위한 initializer
    init(postType: PostType, fontSize: CGFloat = 12) {
        // 임시 Post 객체 생성 (recommendationType은 nil로 처리)
        self.post = Post(
            id: 0,
            userId: 0,
            userName: "",
            userProfileImage: nil,
            postType: postType,
            visibility: "PUBLIC",
            bookInfo: BookInfo(
                isbn: "",
                title: "",
                author: "",
                publisher: "",
                cover: "",
                pubDate: "",
                description: nil
            ),
            createdAt: "",
            updatedAt: "",
            commentCount: nil,
            title: nil,
            content: nil,
            recommendationType: nil,
            reason: nil,
            quotes: nil,
            quote: nil,
            pageNumber: nil
        )
        self.fontSize = fontSize
    }
    
    var body: some View {
        if post.postType == .recommendation {
            // 추천/비추천인 경우
            let isRecommend = post.recommendationType == "RECOMMEND"
            let text = isRecommend ? "추천" : "비추천"
            let backgroundColor = isRecommend 
                ? Color(red: 0.86, green: 0.99, blue: 0.91) // green-100
                : Color(red: 1.0, green: 0.89, blue: 0.89) // red-100
            let textColor = isRecommend
                ? Color(red: 0.09, green: 0.40, blue: 0.20) // green-800
                : Color(red: 0.60, green: 0.11, blue: 0.11) // red-800
            
            Text(text)
                .font(.system(size: fontSize, weight: .medium))
                .foregroundColor(textColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(backgroundColor)
                .cornerRadius(6)
        } else {
            // 다른 게시글 타입
            let (bgColor, txtColor) = typeColors(for: post.postType)
            TypeTag(text: post.postType.displayName, backgroundColor: bgColor, textColor: txtColor, fontSize: fontSize)
        }
    }
    
    private func typeColors(for type: PostType) -> (backgroundColor: Color, textColor: Color) {
        switch type {
        case .review:
            // blue-100: rgb(219, 234, 254), blue-800: rgb(30, 64, 175)
            return (
                Color(red: 0.86, green: 0.92, blue: 1.0), // blue-100
                Color(red: 0.12, green: 0.25, blue: 0.69) // blue-800
            )
        case .quote:
            // purple-100: rgb(243, 232, 255), purple-800: rgb(107, 33, 168)
            return (
                Color(red: 0.95, green: 0.91, blue: 1.0), // purple-100
                Color(red: 0.42, green: 0.13, blue: 0.66) // purple-800
            )
        case .recommendation:
            // 이 경우는 위에서 처리되므로 여기서는 사용되지 않음
            return (.green, .white)
        }
    }
    
    private func typeColor(for type: PostType) -> Color {
        switch type {
        case .review: 
            // blue-100: rgb(219, 234, 254), blue-800: rgb(30, 64, 175)
            return Color(red: 0.12, green: 0.25, blue: 0.69) // blue-800
        case .quote: 
            // purple-100: rgb(243, 232, 255), purple-800: rgb(107, 33, 168)
            return Color(red: 0.42, green: 0.13, blue: 0.66) // purple-800
        case .recommendation:
            // 이 경우는 위에서 처리되므로 여기서는 사용되지 않음
            return .green
        }
    }
}

#Preview {
    VStack {
        PostTypeTag(postType: .review)
        PostTypeTag(postType: .recommendation)
        PostTypeTag(postType: .quote)
    }
    .padding()
}

