//
//  CurrentlyReadingService.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import Foundation
import Combine

enum ReadingType: String, Codable {
    case paperBook = "PAPER_BOOK"
    case libraryRental = "LIBRARY_RENTAL"
    case millie = "MILLIE"
    case eBook = "E_BOOK"
    
    var displayName: String {
        switch self {
        case .paperBook: return "종이책 소장"
        case .libraryRental: return "도서관 대여"
        case .millie: return "밀리의 서재"
        case .eBook: return "전자책 소장"
        }
    }
}

struct CurrentlyReadingCreateRequest: Codable {
    let title: String
    let author: String?
    let coverImage: String?
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let readingType: ReadingType
    let dueDate: String?
    let progressPercentage: Int
    let memo: String?
}

struct CurrentlyReadingUpdateRequest: Codable {
    let title: String
    let author: String?
    let coverImage: String?
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let readingType: ReadingType
    let dueDate: String?
    let progressPercentage: Int
    let memo: String?
}

struct ProgressUpdateRequest: Codable {
    let progressPercentage: Int
    let memo: String?
}

class CurrentlyReadingService {
    static let shared = CurrentlyReadingService()
    private let api = APIService.shared
    
    private init() {}
    
    // 읽고 있는 책 목록 조회
    func getCurrentlyReading(page: Int = 0, size: Int = 10, search: String? = nil) -> AnyPublisher<PageResponse<CurrentlyReading>, Error> {
        var params = "page=\(page)&size=\(size)"
        if let search = search, !search.isEmpty {
            params += "&search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        return api.get(endpoint: "/currently-reading?\(params)")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 읽고 있는 책 상세 조회
    func getCurrentlyReadingById(id: Int) -> AnyPublisher<CurrentlyReading, Error> {
        return api.get(endpoint: "/currently-reading/\(id)")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 읽고 있는 책 추가
    func addCurrentlyReading(_ book: CurrentlyReadingCreateRequest) -> AnyPublisher<CurrentlyReading, Error> {
        return api.post(endpoint: "/currently-reading", body: book)
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 읽고 있는 책 수정
    func updateCurrentlyReading(id: Int, book: CurrentlyReadingUpdateRequest) -> AnyPublisher<CurrentlyReading, Error> {
        return api.put(endpoint: "/currently-reading/\(id)", body: book)
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 진행률 업데이트
    func updateProgress(id: Int, progress: ProgressUpdateRequest) -> AnyPublisher<CurrentlyReading, Error> {
        return api.put(endpoint: "/currently-reading/\(id)/progress", body: progress)
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 읽고 있는 책 삭제
    func deleteCurrentlyReading(id: Int) -> AnyPublisher<Void, Error> {
        return api.deleteVoid(endpoint: "/currently-reading/\(id)")
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    // 책 검색
    func searchBooks(query: String, maxResults: Int = 10) -> AnyPublisher<[BookSearchResult], Error> {
        let params = "query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&maxResults=\(maxResults)"
        return api.get(endpoint: "/currently-reading/search?\(params)")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 중복 체크
    func checkDuplicate(title: String, author: String?) -> AnyPublisher<CurrentlyReadingDuplicateCheckResponse, Error> {
        var params = "title=\(title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let author = author {
            params += "&author=\(author.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        return api.get(endpoint: "/currently-reading/check-duplicate?\(params)")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 연체된 책 목록 조회
    func getOverdueBooks() -> AnyPublisher<[CurrentlyReading], Error> {
        return api.get(endpoint: "/currently-reading/overdue")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
}

struct CurrentlyReadingDuplicateCheckResponse: Codable {
    let duplicate: Bool
    let duplicateBooks: [CurrentlyReading]?
}

