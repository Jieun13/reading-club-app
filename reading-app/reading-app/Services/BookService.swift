//
//  BookService.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import Foundation
import Combine

struct BookCreateRequest: Codable {
    let title: String
    let author: String?
    let coverImage: String?
    let rating: Int
    let review: String?
    let finishedDate: String
}

struct BookUpdateRequest: Codable {
    let title: String
    let author: String?
    let coverImage: String?
    let rating: Int
    let review: String?
    let finishedDate: String
}

struct MonthlyStats: Codable {
    let year: Int
    let month: Int
    let count: Int
    let averageRating: Double
}

class BookService {
    static let shared = BookService()
    private let api = APIService.shared
    
    private init() {}
    
    // 책 목록 조회
    func getBooks(
        page: Int = 0,
        size: Int = 100,
        year: Int? = nil,
        month: Int? = nil,
        rating: Int? = nil,
        search: String? = nil
    ) -> AnyPublisher<PageResponse<Book>, Error> {
        var params = "page=\(page)&size=\(size)"
        if let year = year { params += "&year=\(year)" }
        if let month = month { params += "&month=\(month)" }
        if let rating = rating { params += "&rating=\(rating)" }
        if let search = search, !search.isEmpty { params += "&search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
        
        return api.get(endpoint: "/books?\(params)")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 책 추가
    func addBook(_ book: BookCreateRequest) -> AnyPublisher<Book, Error> {
        return api.post(endpoint: "/books", body: book)
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 책 수정
    func updateBook(id: Int, book: BookUpdateRequest) -> AnyPublisher<Book, Error> {
        return api.put(endpoint: "/books/\(id)", body: book)
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 책 삭제
    func deleteBook(id: Int) -> AnyPublisher<Void, Error> {
        return api.deleteVoid(endpoint: "/books/\(id)")
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    // 책 상세 조회
    func getBook(id: Int) -> AnyPublisher<Book, Error> {
        return api.get(endpoint: "/books/\(id)")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 책 검색
    func searchBooks(query: String, maxResults: Int = 10) -> AnyPublisher<[BookSearchResult], Error> {
        let params = "query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&maxResults=\(maxResults)"
        return api.get(endpoint: "/books/search?\(params)")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 중복 체크
    func checkDuplicate(title: String, author: String?) -> AnyPublisher<DuplicateCheckResponse, Error> {
        var params = "title=\(title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let author = author {
            params += "&author=\(author.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        return api.get(endpoint: "/books/check-duplicate?\(params)")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 월별 통계
    func getMonthlyStatistics() -> AnyPublisher<[MonthlyStats], Error> {
        return api.get(endpoint: "/books/statistics/monthly")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
}

struct DuplicateCheckResponse: Codable {
    let duplicate: Bool
    let duplicateBooks: [Book]?
}

