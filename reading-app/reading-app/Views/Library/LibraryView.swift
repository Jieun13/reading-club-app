//
//  LibraryView.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import SwiftUI
import Combine

struct LibraryView: View {
    @State private var selectedFilter: BookStatus? = nil
    @State private var selectedRating: Int? = nil
    @State private var searchText = ""
    @State private var books: [Book] = []
    @State private var currentlyReading: [CurrentlyReading] = []
    @State private var droppedBooks: [DroppedBook] = []
    @State private var wishlists: [Wishlist] = []
    @State private var isLoading = false
    @State private var showingAddBook = false
    @State private var selectedBookStatus: BookStatus = .completed
    @State private var cancellables = Set<AnyCancellable>()
    
    var displayedBooks: [Any] {
        let searchLower = searchText.lowercased()
        var allItems: [Any] = []
        
        if selectedFilter == nil || selectedFilter == .completed {
            let filtered = books.filter { book in
                let matchesSearch = searchText.isEmpty || book.title.lowercased().contains(searchLower) || (book.author?.lowercased().contains(searchLower) ?? false)
                let matchesRating = selectedRating == nil || book.rating == selectedRating
                return matchesSearch && matchesRating
            }
            allItems.append(contentsOf: filtered)
        }
        
        if selectedFilter == nil || selectedFilter == .currentlyReading {
            let filtered = currentlyReading.filter { book in
                searchText.isEmpty || book.title.lowercased().contains(searchLower) || (book.author?.lowercased().contains(searchLower) ?? false)
            }
            allItems.append(contentsOf: filtered)
        }
        
        if selectedFilter == nil || selectedFilter == .dropped {
            let filtered = droppedBooks.filter { book in
                searchText.isEmpty || book.title.lowercased().contains(searchLower) || (book.author?.lowercased().contains(searchLower) ?? false)
            }
            allItems.append(contentsOf: filtered)
        }
        
        if selectedFilter == nil || selectedFilter == .wishlist {
            let filtered = wishlists.filter { book in
                searchText.isEmpty || book.title.lowercased().contains(searchLower) || (book.author?.lowercased().contains(searchLower) ?? false)
            }
            allItems.append(contentsOf: filtered)
        }
        
        return allItems
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 필터 탭
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterButton(
                            title: "전체",
                            isSelected: selectedFilter == nil
                        ) {
                            selectedFilter = nil
                            selectedRating = nil
                        }
                        
                        ForEach(BookStatus.allCases, id: \.self) { status in
                            FilterButton(
                                title: status.displayName,
                                isSelected: selectedFilter == status
                            ) {
                                selectedFilter = status
                                if status != .completed {
                                    selectedRating = nil
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Color(.systemBackground))
                
                // 검색 바
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("제목, 저자로 검색", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                
                // 별점 필터 (완독 탭일 때만 표시)
                if selectedFilter == .completed {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterButton(
                                title: "전체",
                                isSelected: selectedRating == nil
                            ) {
                                selectedRating = nil
                            }
                            
                            ForEach(1...5, id: \.self) { rating in
                                FilterButton(
                                    title: "\(rating)점",
                                    isSelected: selectedRating == rating
                                ) {
                                    selectedRating = rating
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .background(Color(.systemBackground))
                }
                
                // 책 그리드
                if isLoading && books.isEmpty && currentlyReading.isEmpty && droppedBooks.isEmpty && wishlists.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if displayedBooks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("등록된 책이 없습니다")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ], spacing: 12) {
                            ForEach(Array(displayedBooks.enumerated()), id: \.offset) { index, item in
                                if let book = item as? Book {
                                    BookCard(book: book)
                                } else if let currentlyReading = item as? CurrentlyReading {
                                    CurrentlyReadingCard(book: currentlyReading)
                                } else if let droppedBook = item as? DroppedBook {
                                    DroppedBookCard(book: droppedBook)
                                } else if let wishlist = item as? Wishlist {
                                    WishlistCard(book: wishlist)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle("내 서재")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            selectedBookStatus = .completed
                            showingAddBook = true
                        }) {
                            Label("완독한 책 추가", systemImage: "checkmark.circle")
                        }
                        
                        Button(action: {
                            selectedBookStatus = .currentlyReading
                            showingAddBook = true
                        }) {
                            Label("읽고 있는 책 추가", systemImage: "book.fill")
                        }
                        
                        Button(action: {
                            selectedBookStatus = .dropped
                            showingAddBook = true
                        }) {
                            Label("읽다 만 책 추가", systemImage: "xmark.circle")
                        }
                        
                        Button(action: {
                            selectedBookStatus = .wishlist
                            showingAddBook = true
                        }) {
                            Label("위시리스트 추가", systemImage: "bookmark.fill")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddBook, onDismiss: {
                // 책 추가 후 목록 새로고침
                loadBooks()
            }) {
                AddBookView(bookStatus: selectedBookStatus)
            }
            .onAppear {
                loadBooks()
            }
            .onChange(of: selectedFilter) { _ in
                // 필터 변경 시 재로드 불필요 (이미 displayedBooks에서 필터링)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshLibrary"))) { _ in
                loadBooks()
            }
        }
    }
    
    private func loadBooks() {
        isLoading = true
        
        let group = DispatchGroup()
        
        // 완독한 책
        group.enter()
        BookService.shared.getBooks(page: 0, size: 100)
            .sink(
                receiveCompletion: { _ in group.leave() },
                receiveValue: { response in
                    books = response.content
                }
            )
            .store(in: &cancellables)
        
        // 읽고 있는 책
        group.enter()
        CurrentlyReadingService.shared.getCurrentlyReading(page: 0, size: 100)
            .sink(
                receiveCompletion: { _ in group.leave() },
                receiveValue: { response in
                    currentlyReading = response.content
                }
            )
            .store(in: &cancellables)
        
        // 읽다 만 책
        group.enter()
        DroppedBookService.shared.getDroppedBooks(page: 0, size: 100)
            .sink(
                receiveCompletion: { _ in group.leave() },
                receiveValue: { response in
                    droppedBooks = response.content
                }
            )
            .store(in: &cancellables)
        
        // 위시리스트
        group.enter()
        WishlistService.shared.getWishlists(page: 0, size: 100)
            .sink(
                receiveCompletion: { _ in group.leave() },
                receiveValue: { response in
                    wishlists = response.content
                }
            )
            .store(in: &cancellables)
        
        group.notify(queue: .main) {
            isLoading = false
        }
    }
}

struct CurrentlyReadingCard: View {
    let book: CurrentlyReading
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(alignment: .leading, spacing: 8) {
                AsyncImage(url: URL(string: book.coverImage ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay {
                            Image(systemName: "book.closed")
                                .font(.system(size: 30))
                                .foregroundColor(.secondary)
                        }
                }
                .frame(height: 160)
                .cornerRadius(8)
                .clipped()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    if let author = book.author {
                        Text(author)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    ProgressView(value: Double(book.progressPercentage), total: 100)
                        .tint(.blue)
                }
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail, onDismiss: {
            // 모달이 닫힐 때 목록 새로고침
            NotificationCenter.default.post(name: NSNotification.Name("RefreshLibrary"), object: nil)
        }) {
            CurrentlyReadingDetailModal(book: book)
        }
    }
}

struct DroppedBookCard: View {
    let book: DroppedBook
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(alignment: .leading, spacing: 8) {
                AsyncImage(url: URL(string: book.coverImage ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay {
                            Image(systemName: "book.closed")
                                .font(.system(size: 30))
                                .foregroundColor(.secondary)
                        }
                }
                .frame(height: 160)
                .cornerRadius(8)
                .clipped()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    if let author = book.author {
                        Text(author)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail, onDismiss: {
            // 모달이 닫힐 때 목록 새로고침
            NotificationCenter.default.post(name: NSNotification.Name("RefreshLibrary"), object: nil)
        }) {
            DroppedBookDetailModal(book: book)
        }
    }
}

struct WishlistCard: View {
    let book: Wishlist
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(alignment: .leading, spacing: 8) {
                AsyncImage(url: URL(string: book.coverImage ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay {
                            Image(systemName: "book.closed")
                                .font(.system(size: 30))
                                .foregroundColor(.secondary)
                        }
                }
                .frame(height: 160)
                .cornerRadius(8)
                .clipped()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    if let author = book.author {
                        Text(author)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail, onDismiss: {
            // 모달이 닫힐 때 목록 새로고침
            NotificationCenter.default.post(name: NSNotification.Name("RefreshLibrary"), object: nil)
        }) {
            WishlistDetailModal(book: book)
        }
    }
}


struct BookCard: View {
    let book: Book
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // 책 표지
                AsyncImage(url: URL(string: book.coverImage ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay {
                            Image(systemName: "book.closed")
                                .font(.system(size: 30))
                                .foregroundColor(.secondary)
                        }
                }
                .frame(height: 160)
                .cornerRadius(8)
                .clipped()
                
                // 책 정보
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    if let author = book.author {
                        Text(author)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    if book.rating > 0 {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { index in
                                Image(systemName: index <= book.rating ? "star.fill" : "star")
                                    .font(.system(size: 9))
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail, onDismiss: {
            // 모달이 닫힐 때 목록 새로고침
            NotificationCenter.default.post(name: NSNotification.Name("RefreshLibrary"), object: nil)
        }) {
            BookDetailModal(book: book)
        }
    }
}

#Preview {
    LibraryView()
}
