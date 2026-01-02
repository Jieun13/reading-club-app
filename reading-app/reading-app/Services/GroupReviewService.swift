//
//  GroupReviewService.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import Foundation
import Combine

struct GroupReviewCreateRequest: Codable {
    let readingGroupId: Int
    let rating: Int
    let title: String
    let content: String
    let favoriteQuote: String?
    let recommendation: String?
    let isPublic: Bool
}

struct GroupReviewUpdateRequest: Codable {
    let rating: Int?
    let title: String?
    let content: String?
    let favoriteQuote: String?
    let recommendation: String?
    let isPublic: Bool?
}

class GroupReviewService {
    static let shared = GroupReviewService()
    private let api = APIService.shared
    
    private init() {}
    
    // 독서모임 리뷰 작성
    func createReview(_ review: GroupReviewCreateRequest) -> AnyPublisher<GroupReview, Error> {
        return api.post(endpoint: "/group-reviews", body: review)
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 독서모임의 공개 리뷰 목록 조회
    func getGroupReviews(groupId: Int) -> AnyPublisher<[GroupReview], Error> {
        return api.get(endpoint: "/group-reviews/group/\(groupId)")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 내 리뷰 조회
    func getMyReview(groupId: Int) -> AnyPublisher<GroupReview?, Error> {
        return api.get(endpoint: "/group-reviews/my-review/\(groupId)")
            .map { (response: APIResponse<GroupReview>) in response.data }
            .catch { _ in Just(nil).setFailureType(to: Error.self) }
            .eraseToAnyPublisher()
    }
    
    // 리뷰 수정
    func updateReview(reviewId: Int, review: GroupReviewUpdateRequest) -> AnyPublisher<GroupReview, Error> {
        return api.put(endpoint: "/group-reviews/\(reviewId)", body: review)
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 리뷰 삭제
    func deleteReview(reviewId: Int) -> AnyPublisher<Void, Error> {
        return api.deleteVoid(endpoint: "/group-reviews/\(reviewId)")
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}

