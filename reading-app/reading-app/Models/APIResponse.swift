//
//  APIResponse.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import Foundation

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T
    let message: String
    let timestamp: String
}

struct PageResponse<T: Codable>: Codable {
    let content: [T]
    let pageable: Pageable
    let last: Bool
    let totalPages: Int
    let totalElements: Int
    let size: Int
    let number: Int
    let first: Bool
    let numberOfElements: Int
    let empty: Bool
}

struct Pageable: Codable {
    let pageNumber: Int
    let pageSize: Int
    let sort: Sort
    let offset: Int
    let paged: Bool
    let unpaged: Bool
}

struct Sort: Codable {
    let empty: Bool
    let sorted: Bool
    let unsorted: Bool
}

