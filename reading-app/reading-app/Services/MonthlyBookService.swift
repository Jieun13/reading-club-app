//
//  MonthlyBookService.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import Foundation
import Combine

struct MonthlyBookSelectRequest: Codable {
    let title: String
    let author: String
    let publisher: String
    let coverImage: String?
    let description: String?
    let year: Int
    let month: Int
}

class MonthlyBookService {
    static let shared = MonthlyBookService()
    private let api = APIService.shared
    
    private init() {}
    
    // 현재 월간 도서 조회
    func getCurrentMonthlyBook(groupId: Int) -> AnyPublisher<MonthlyBook, Error> {
        return api.get(endpoint: "/reading-groups/\(groupId)/monthly-books/current")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 그룹의 월간 도서 목록 조회
    func getGroupMonthlyBooks(groupId: Int) -> AnyPublisher<[MonthlyBook], Error> {
        return api.get(endpoint: "/reading-groups/\(groupId)/monthly-books")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 월간 도서 선정
    func selectMonthlyBook(groupId: Int, request: MonthlyBookSelectRequest) -> AnyPublisher<MonthlyBook, Error> {
        return api.post(endpoint: "/reading-groups/\(groupId)/monthly-books", body: request)
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 월간 도서 상태 변경
    func updateMonthlyBookStatus(groupId: Int, monthlyBookId: Int, status: String) -> AnyPublisher<MonthlyBook, Error> {
        return api.put(endpoint: "/reading-groups/\(groupId)/monthly-books/\(monthlyBookId)/status?status=\(status)", body: EmptyBody())
            .map { $0.data }
            .eraseToAnyPublisher()
    }
}

