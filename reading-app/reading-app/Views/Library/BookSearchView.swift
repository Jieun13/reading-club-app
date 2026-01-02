//
//  BookSearchView.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import SwiftUI
import Combine

struct BookSearchView: View {
    @Binding var selectedBook: BookSearchResult?
    @Environment(\.dismiss) var dismiss
    
    @State private var searchQuery = ""
    @State private var searchResults: [BookSearchResult] = []
    @State private var isSearching = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 검색 바
                HStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                        
                        TextField("책 제목 또는 작가를 검색하세요", text: $searchQuery)
                            .font(.system(size: 15))
                            .onSubmit {
                                performSearch()
                            }
                        
                        if !searchQuery.isEmpty {
                            Button(action: {
                                searchQuery = ""
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
                    
                    Button(action: {
                        performSearch()
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 44, height: 44)
                            .background(searchQuery.trimmingCharacters(in: .whitespaces).isEmpty || isSearching ? Color.gray.opacity(0.3) : Color.blue)
                            .cornerRadius(12)
                    }
                    .disabled(searchQuery.trimmingCharacters(in: .whitespaces).isEmpty || isSearching)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                
                // 검색 결과
                if isSearching {
                    Spacer()
                    ProgressView("검색 중...")
                    Spacer()
                } else if searchResults.isEmpty && !searchQuery.isEmpty {
                    EmptyStateView(icon: "book.closed", message: "검색 결과가 없습니다", iconSize: 50, fontSize: 14)
                } else if searchResults.isEmpty {
                    EmptyStateView(icon: "magnifyingglass", message: "책을 검색해보세요", iconSize: 50, fontSize: 14)
                } else {
                    List {
                        ForEach(searchResults) { book in
                            BookSearchResultRow(book: book) {
                                selectedBook = book
                                dismiss()
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("책 검색")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
            .alert("오류", isPresented: .constant(errorMessage != nil)) {
                Button("확인") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private func performSearch() {
        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        searchResults = []
        
        BookService.shared.searchBooks(query: query, maxResults: 20)
            .sink(
                receiveCompletion: { completion in
                    isSearching = false
                    if case .failure(let error) = completion {
                        errorMessage = "검색 실패: \(error.localizedDescription)"
                    }
                },
                receiveValue: { results in
                    searchResults = results
                }
            )
            .store(in: &cancellables)
    }
}

struct BookSearchResultRow: View {
    let book: BookSearchResult
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // 책 표지
                BookCoverImage(imageUrl: book.cover, width: 60, height: 80, cornerRadius: 6)
                
                // 책 정보
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    if let author = book.author {
                        Text(author)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    if let publisher = book.publisher {
                        Text(publisher)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    BookSearchView(selectedBook: .constant(nil))
}
