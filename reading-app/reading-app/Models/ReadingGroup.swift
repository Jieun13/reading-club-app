//
//  ReadingGroup.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import Foundation

struct ReadingGroup: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let isPublic: Bool
    let inviteCode: String?
    let memberCount: Int?
    let createdAt: String
    let updatedAt: String
}

struct MonthlyBook: Codable, Identifiable {
    let id: Int
    let group: MonthlyBookGroup?
    let title: String
    let author: String
    let publisher: String
    let coverImage: String?
    let description: String?
    let year: Int
    let month: Int
    let status: String?
    let createdAt: String
    let updatedAt: String
}

struct MonthlyBookGroup: Codable {
    let id: Int
    let name: String
}

struct GroupReview: Codable, Identifiable {
    let id: Int
    let user: GroupReviewUser
    let readingGroup: GroupReviewGroup?
    let rating: Int
    let title: String
    let content: String
    let favoriteQuote: String?
    let recommendation: String?
    let isPublic: Bool
    let createdAt: String
    let updatedAt: String
}

struct GroupReviewUser: Codable {
    let id: Int
    let nickname: String
    let profileImage: String?
}

struct GroupReviewGroup: Codable {
    let id: Int
    let name: String
}

