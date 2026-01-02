//
//  PostsView.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import SwiftUI
import Combine

struct PostsView: View {
    @State private var selectedType: PostType? = nil
    @State private var posts: [Post] = []
    @State private var showingCreatePost = false
    @State private var isLoading = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var currentPage = 0
    @State private var hasMore = true
    @State private var searchText = ""
    @State private var isSearchMode = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 타입 필터 탭
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterButton(
                            title: "전체",
                            isSelected: selectedType == nil
                        ) {
                            selectedType = nil
                        }
                        
                        ForEach(PostType.allCases, id: \.self) { type in
                            FilterButton(
                                title: type.displayName,
                                isSelected: selectedType == type
                            ) {
                                selectedType = type
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Color(.systemBackground))
                
                // 검색 바
                HStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                        
                        TextField("책 제목, 작가, 작성자로 검색", text: $searchText)
                            .font(.system(size: 15))
                            .onSubmit {
                                performSearch()
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                isSearchMode = false
                                loadPosts()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 16))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            performSearch()
                        }) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .semibold))
                                .frame(width: 44, height: 44)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                
                // 게시글 그리드
                if isLoading && posts.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if posts.isEmpty {
                    EmptyStateView(icon: "square.and.pencil", message: "등록된 게시글이 없습니다", iconSize: 50, fontSize: 14)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(posts) { post in
                                NavigationLink(destination: PostDetailView(post: post)) {
                                    PostCard(post: post)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            if hasMore && !isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .onAppear {
                                        loadMorePosts()
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle("게시글")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreatePost = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingCreatePost) {
                CreatePostView()
            }
            .onAppear {
                loadPosts()
            }
            .onChange(of: selectedType) { _ in
                currentPage = 0
                posts = []
                if isSearchMode {
                    performSearch()
                } else {
                    loadPosts()
                }
            }
        }
    }
    
    private func loadPosts() {
        isLoading = true
        currentPage = 0
        isSearchMode = false
        
        PostService.shared.getAllPosts(
            postType: selectedType,
            page: currentPage,
            size: 20
        )
        .sink(
            receiveCompletion: { completion in
                isLoading = false
                if case .failure = completion {
                    // 에러 처리
                }
            },
            receiveValue: { response in
                posts = response.posts
                currentPage = response.currentPage
                hasMore = response.currentPage < response.totalPages - 1
            }
        )
        .store(in: &cancellables)
    }
    
    private func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        
        guard !query.isEmpty else {
            isSearchMode = false
            loadPosts()
            return
        }
        
        isLoading = true
        currentPage = 0
        isSearchMode = true
        posts = []
        
        PostService.shared.searchPosts(
            keyword: query,
            bookTitle: nil,
            postType: selectedType,
            page: currentPage,
            size: 20
        )
        .sink(
            receiveCompletion: { completion in
                isLoading = false
                if case .failure = completion {
                    posts = []
                    hasMore = false
                }
            },
            receiveValue: { response in
                posts = response.posts
                currentPage = response.currentPage
                hasMore = response.currentPage < response.totalPages - 1
            }
        )
        .store(in: &cancellables)
    }
    
    private func loadMorePosts() {
        guard !isLoading && hasMore else { return }
        isLoading = true
        
        if isSearchMode {
            let query = searchText.trimmingCharacters(in: .whitespaces)
            PostService.shared.searchPosts(
                keyword: query,
                bookTitle: nil,
                postType: selectedType,
                page: currentPage + 1,
                size: 20
            )
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        print("게시글 추가 검색 실패: \(error)")
                    }
                },
                receiveValue: { response in
                    posts.append(contentsOf: response.posts)
                    currentPage = response.currentPage
                    hasMore = response.currentPage < response.totalPages - 1
                }
            )
            .store(in: &cancellables)
        } else {
            PostService.shared.getAllPosts(
                postType: selectedType,
                page: currentPage + 1,
                size: 20
            )
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        print("게시글 추가 로드 실패: \(error)")
                    }
                },
                receiveValue: { response in
                    posts.append(contentsOf: response.posts)
                    currentPage = response.currentPage
                    hasMore = response.currentPage < response.totalPages - 1
                }
            )
            .store(in: &cancellables)
        }
    }
}


#Preview {
    PostsView()
}

