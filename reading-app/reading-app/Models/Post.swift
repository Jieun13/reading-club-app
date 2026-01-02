//
//  Post.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import Foundation

enum PostType: String, Codable, CaseIterable {
    case review = "REVIEW"
    case recommendation = "RECOMMENDATION"
    case quote = "QUOTE"
    
    var displayName: String {
        switch self {
        case .review: return "독후감"
        case .recommendation: return "추천/비추천"
        case .quote: return "문장 수집"
        }
    }
}

struct Post: Codable, Identifiable {
    let id: Int
    let userId: Int
    let userName: String
    let userProfileImage: String?
    let postType: PostType
    let visibility: String
    let bookInfo: BookInfo
    let createdAt: String
    let updatedAt: String
    let commentCount: Int?
    
    // 독후감 필드
    let title: String?
    let content: String?
    
    // 추천/비추천 필드
    let recommendationType: String?
    let reason: String?
    
    // 문장 수집 필드
    let quotes: [Quote]?
    let quote: String?
    let pageNumber: Int?
}

struct BookInfo: Codable {
    let isbn: String
    let title: String
    let author: String
    let publisher: String
    let cover: String
    let pubDate: String
    let description: String?
    
    var coverImage: String? { cover }
}

struct Comment: Codable, Identifiable {
    let id: Int
    let content: String
    let isDeleted: Bool
    let isReply: Bool
    let parentId: Int?
    let replyCount: Int
    let canDelete: Bool
    let createdAt: String
    let updatedAt: String
    let user: CommentUser
    let replies: [Comment]?
}

struct CommentUser: Codable {
    let id: Int
    let nickname: String
    let profileImage: String?
}

struct Quote: Codable {
    let page: String
    let text: String
    
    // 기본 initializer
    init(page: String, text: String) {
        self.page = page
        self.text = text
    }
    
    // API에서 page가 숫자로 올 수도 있으므로 커스텀 디코딩
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        
        // page는 String 또는 Int로 올 수 있음
        if let pageString = try? container.decode(String.self, forKey: .page) {
            page = pageString
        } else if let pageInt = try? container.decode(Int.self, forKey: .page) {
            page = String(pageInt)
        } else {
            page = ""
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encode(page, forKey: .page)
    }
    
    enum CodingKeys: String, CodingKey {
        case page, text
    }
}

