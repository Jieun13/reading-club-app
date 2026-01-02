//
//  PostService.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import Foundation
import Combine

enum RecommendationType: String, Codable {
    case recommend = "RECOMMEND"
    case notRecommend = "NOT_RECOMMEND"
}

enum PostVisibility: String, Codable {
    case `public` = "PUBLIC"
    case `private` = "PRIVATE"
}

struct CreatePostRequest: Codable {
    let bookInfo: BookInfo
    let postType: PostType
    let visibility: PostVisibility
    let title: String?
    let content: String?
    let recommendationType: RecommendationType?
    let reason: String?
    let quotes: [Quote]?
    let quote: String?
    let pageNumber: Int?
}

struct PostListResponse: Codable {
    let posts: [Post]
    let totalCount: Int
    let currentPage: Int
    let totalPages: Int
}

class PostService {
    static let shared = PostService()
    private let api = APIService.shared
    
    private init() {}
    
    // 게시글 목록 조회 (내 게시글만)
    func getPosts(
        postType: PostType? = nil,
        visibility: PostVisibility? = nil,
        page: Int = 0,
        size: Int = 20
    ) -> AnyPublisher<PostListResponse, Error> {
        var params = "page=\(page)&size=\(size)"
        if let postType = postType { params += "&postType=\(postType.rawValue)" }
        if let visibility = visibility { params += "&visibility=\(visibility.rawValue)" }
        return api.get(endpoint: "/posts?\(params)")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 통합 게시글 목록 조회 (다른 사람 공개 + 내 모든 게시글)
    func getAllPosts(
        postType: PostType? = nil,
        page: Int = 0,
        size: Int = 20
    ) -> AnyPublisher<PostListResponse, Error> {
        var params = "page=\(page)&size=\(size)"
        if let postType = postType {
            params += "&postType=\(postType.rawValue)"
        }
        return api.get(endpoint: "/posts/all?\(params)")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 게시글 검색
    func searchPosts(
        keyword: String? = nil,
        bookTitle: String? = nil,
        postType: PostType? = nil,
        page: Int = 0,
        size: Int = 20
    ) -> AnyPublisher<PostListResponse, Error> {
        var params: [String] = []
        if let keyword = keyword, !keyword.isEmpty {
            let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keyword
            params.append("keyword=\(encodedKeyword)")
        }
        if let bookTitle = bookTitle, !bookTitle.isEmpty {
            let encodedBookTitle = bookTitle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? bookTitle
            params.append("bookTitle=\(encodedBookTitle)")
        }
        if let postType = postType {
            params.append("postType=\(postType.rawValue)")
        }
        params.append("page=\(page)")
        params.append("size=\(size)")
        
        let queryString = params.joined(separator: "&")
        let endpoint = "/posts/search?\(queryString)"
        
        // 검색 API는 PageResponse 형태로 응답을 반환할 수 있음
        return api.get(endpoint: endpoint)
            .tryMap { (response: APIResponse<PageResponse<Post>>) -> PostListResponse in
                let pageResponse = response.data
                return PostListResponse(
                    posts: pageResponse.content,
                    totalCount: pageResponse.totalElements,
                    currentPage: pageResponse.number,
                    totalPages: pageResponse.totalPages
                )
            }
            .catch { _ -> AnyPublisher<PostListResponse, Error> in
                // PageResponse가 아닌 경우 PostListResponse로 시도
                return self.api.get(endpoint: endpoint)
                    .map { $0.data }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // 게시글 상세 조회
    func getPost(id: Int) -> AnyPublisher<Post, Error> {
        return api.get(endpoint: "/posts/\(id)")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 게시글 생성
    func createPost(_ post: CreatePostRequest) -> AnyPublisher<Post, Error> {
        return api.post(endpoint: "/posts", body: post)
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 게시글 수정
    func updatePost(id: Int, post: CreatePostRequest) -> AnyPublisher<Post, Error> {
        return api.put(endpoint: "/posts/\(id)", body: post)
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 게시글 삭제
    func deletePost(id: Int) -> AnyPublisher<Void, Error> {
        return api.deleteVoid(endpoint: "/posts/\(id)")
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    // 내 게시글 목록 조회
    func getMyPosts(
        postType: PostType? = nil,
        visibility: PostVisibility? = nil,
        page: Int = 0,
        size: Int = 20
    ) -> AnyPublisher<PostListResponse, Error> {
        var params = "page=\(page)&size=\(size)"
        if let postType = postType { params += "&postType=\(postType.rawValue)" }
        if let visibility = visibility { params += "&visibility=\(visibility.rawValue)" }
        return api.get(endpoint: "/posts/my?\(params)")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 특정 사용자의 게시글 목록 조회
    func getUserPosts(
        userId: Int,
        postType: PostType? = nil,
        visibility: PostVisibility? = nil,
        page: Int = 0,
        size: Int = 20
    ) -> AnyPublisher<PostListResponse, Error> {
        var params = "page=\(page)&size=\(size)"
        if let postType = postType { params += "&postType=\(postType.rawValue)" }
        if let visibility = visibility { params += "&visibility=\(visibility.rawValue)" }
        return api.get(endpoint: "/posts/user/\(userId)?\(params)")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
}

// 댓글 관련 서비스
struct CommentCreateRequest: Codable {
    let content: String
    let parentId: Int?
}

struct CommentListResponse: Codable {
    let comments: CommentPageResponse
    let totalComments: Int
    let activeComments: Int
}

struct CommentPageResponse: Codable {
    let content: [Comment]
    let totalElements: Int
    let totalPages: Int
    let number: Int
    let size: Int
}

class CommentService {
    static let shared = CommentService()
    private let api = APIService.shared
    
    private init() {}
    
    // 댓글 목록 조회
    func getComments(postId: Int, page: Int = 0, size: Int = 10) -> AnyPublisher<CommentListResponse, Error> {
        return api.get(endpoint: "/comments/posts/\(postId)?page=\(page)&size=\(size)")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 댓글 작성
    func createComment(postId: Int, request: CommentCreateRequest) -> AnyPublisher<Comment, Error> {
        return api.post(endpoint: "/comments/posts/\(postId)", body: request)
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 댓글 삭제
    func deleteComment(commentId: Int) -> AnyPublisher<Void, Error> {
        return api.deleteVoid(endpoint: "/comments/\(commentId)")
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    // 대댓글 목록 조회
    func getReplies(commentId: Int) -> AnyPublisher<[Comment], Error> {
        return api.get(endpoint: "/comments/\(commentId)/replies")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
}

