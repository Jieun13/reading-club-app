//
//  DroppedBookService.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import Foundation
import Combine

struct DroppedBookCreateRequest: Codable {
    let title: String
    let author: String?
    let isbn: String?
    let coverImage: String?
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let readingType: String?
    let progressPercentage: Int
    let dropReason: String?
    let startedDate: String?
    let droppedDate: String?
}

struct DroppedBookUpdateRequest: Codable {
    let dropReason: String?
    let progressPercentage: Int
}

class DroppedBookService {
    static let shared = DroppedBookService()
    private let api = APIService.shared
    
    private init() {}
    
    // 읽다 만 책 목록 조회
    func getDroppedBooks(page: Int = 0, size: Int = 100, search: String? = nil) -> AnyPublisher<PageResponse<DroppedBook>, Error> {
        var params = "page=\(page)&size=\(size)"
        if let search = search, !search.isEmpty {
            params += "&search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        return api.get(endpoint: "/dropped-books?\(params)")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 읽다 만 책 상세 조회
    func getDroppedBook(id: Int) -> AnyPublisher<DroppedBook, Error> {
        return api.get(endpoint: "/dropped-books/\(id)")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 읽다 만 책 추가
    func addDroppedBook(_ book: DroppedBookCreateRequest) -> AnyPublisher<DroppedBook, Error> {
        return api.post(endpoint: "/dropped-books", body: book)
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 읽다 만 책 수정
    func updateDroppedBook(id: Int, book: DroppedBookUpdateRequest) -> AnyPublisher<DroppedBook, Error> {
        return api.put(endpoint: "/dropped-books/\(id)", body: book)
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 읽다 만 책 삭제
    func deleteDroppedBook(id: Int) -> AnyPublisher<Void, Error> {
        return api.deleteVoid(endpoint: "/dropped-books/\(id)")
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    // 중복 체크
    func checkDuplicate(title: String, author: String?) -> AnyPublisher<DroppedBookDuplicateCheckResponse, Error> {
        var params = "title=\(title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let author = author {
            params += "&author=\(author.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        return api.get(endpoint: "/dropped-books/check-duplicate?\(params)")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
}

struct DroppedBookDuplicateCheckResponse: Codable {
    let duplicate: Bool
    let existingBook: DroppedBook?
}

