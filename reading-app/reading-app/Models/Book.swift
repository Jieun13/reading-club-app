//
//  Book.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import Foundation

enum BookStatus: String, Codable, CaseIterable {
    case completed = "COMPLETED"
    case currentlyReading = "CURRENTLY_READING"
    case dropped = "DROPPED"
    case wishlist = "WISHLIST"
    
    var displayName: String {
        switch self {
        case .completed: return "완독"
        case .currentlyReading: return "읽는 중"
        case .dropped: return "읽다 만 책"
        case .wishlist: return "위시리스트"
        }
    }
}

struct Book: Codable, Identifiable {
    let id: Int
    let title: String
    let author: String?
    let coverImage: String?
    var rating: Int
    var review: String?
    var finishedDate: String
    let createdAt: String
    let updatedAt: String
    let status: BookStatus?
    let user: User?
}

struct BookSearchResult: Codable, Identifiable {
    var id: String { isbn ?? UUID().uuidString }
    let title: String
    let author: String?
    let publisher: String?
    let pubDate: String?
    let description: String?
    let cover: String?
    let isbn: String?
    let categoryName: String?
    let priceStandard: Int?
    
    init(title: String, author: String? = nil, publisher: String? = nil, pubDate: String? = nil, description: String? = nil, cover: String? = nil, isbn: String? = nil, categoryName: String? = nil, priceStandard: Int? = nil) {
        self.title = title
        self.author = author
        self.publisher = publisher
        self.pubDate = pubDate
        self.description = description
        self.cover = cover
        self.isbn = isbn
        self.categoryName = categoryName
        self.priceStandard = priceStandard
    }
}

struct CurrentlyReading: Codable, Identifiable {
    let id: Int
    let title: String
    let author: String?
    let coverImage: String?
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let readingType: String
    let readingTypeDisplay: String?
    let dueDate: String?
    var progressPercentage: Int
    var memo: String?
    let isOverdue: Bool?
    let createdAt: String
    let updatedAt: String
    let user: User?
}

struct DroppedBook: Codable, Identifiable {
    let id: Int
    let title: String
    let author: String?
    let coverImage: String?
    let publisher: String?
    let publishedDate: String?
    let description: String?
    var dropReason: String?
    var progressPercentage: Int
    let createdAt: String
    let updatedAt: String
    let user: User?
}

struct Wishlist: Codable, Identifiable {
    let id: Int
    let title: String
    let author: String?
    let coverImage: String?
    let publisher: String?
    let publishedDate: String?
    let description: String?
    var memo: String?
    let createdAt: String
    let updatedAt: String
    let user: User?
}

