//
//  WishlistService.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import Foundation
import Combine

struct WishlistCreateRequest: Codable {
    let title: String
    let author: String?
    let coverImage: String?
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let memo: String?
}

struct WishlistUpdateRequest: Codable {
    let memo: String?
}

class WishlistService {
    static let shared = WishlistService()
    private let api = APIService.shared
    
    private init() {}
    
    // 위시리스트 목록 조회
    func getWishlists(page: Int = 0, size: Int = 10, search: String? = nil) -> AnyPublisher<PageResponse<Wishlist>, Error> {
        var params = "page=\(page)&size=\(size)"
        if let search = search, !search.isEmpty {
            params += "&search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        return api.get(endpoint: "/wishlists?\(params)")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 위시리스트 상세 조회
    func getWishlist(id: Int) -> AnyPublisher<Wishlist, Error> {
        return api.get(endpoint: "/wishlists/\(id)")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 위시리스트 추가
    func addWishlist(_ wishlist: WishlistCreateRequest) -> AnyPublisher<Wishlist, Error> {
        return api.post(endpoint: "/wishlists", body: wishlist)
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 위시리스트 수정
    func updateWishlist(id: Int, wishlist: WishlistUpdateRequest) -> AnyPublisher<Wishlist, Error> {
        return api.put(endpoint: "/wishlists/\(id)", body: wishlist)
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 위시리스트 삭제
    func deleteWishlist(id: Int) -> AnyPublisher<Void, Error> {
        return api.deleteVoid(endpoint: "/wishlists/\(id)")
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    // 중복 체크
    func checkDuplicate(title: String, author: String?) -> AnyPublisher<WishlistDuplicateCheckResponse, Error> {
        var params = "title=\(title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let author = author {
            params += "&author=\(author.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        return api.get(endpoint: "/wishlists/check-duplicate?\(params)")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
}

struct WishlistDuplicateCheckResponse: Codable {
    let duplicate: Bool
    let duplicateWishlists: [Wishlist]?
}

