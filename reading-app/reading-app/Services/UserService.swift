//
//  UserService.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import Foundation
import Combine

struct UserStatistics: Codable {
    let totalBooks: Int
    let currentlyReadingCount: Int
    let wishlistCount: Int
    let droppedBooksCount: Int
    let totalPosts: Int
    let thisMonthPosts: Int
    let thisMonthBooks: Int
    let thisMonthDroppedBooks: Int
}

struct UserProfile: Codable {
    let id: Int
    let nickname: String
    let profileImage: String?
    let createdAt: String
    let updatedAt: String
    let statistics: UserStatistics
    let currentlyReading: [CurrentlyReading]
    let recentPublicPosts: [Post]
}

struct UpdateUserRequest: Codable {
    let nickname: String?
    let profileImage: String?
}

class UserService {
    static let shared = UserService()
    private let api = APIService.shared
    
    private init() {}
    
    // 내 정보 조회
    func getMyInfo() -> AnyPublisher<User, Error> {
        return api.get(endpoint: "/users/me")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 내 정보 수정
    func updateMyInfo(_ request: UpdateUserRequest) -> AnyPublisher<User, Error> {
        return api.put(endpoint: "/users/me", body: request)
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 내 독서 통계 조회
    func getMyStatistics() -> AnyPublisher<UserStatistics, Error> {
        return api.get(endpoint: "/users/me/statistics")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 특정 사용자 프로필 조회
    func getUserProfile(userId: Int) -> AnyPublisher<UserProfile, Error> {
        return api.get(endpoint: "/users/\(userId)")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
}

