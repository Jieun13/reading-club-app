//
//  AddBookView.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import SwiftUI
import Combine

struct AddBookView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedBook: BookSearchResult?
    @State private var showingBookSearch = false
    @State private var isLoading = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var errorMessage: String?
    
    // 완독한 책용
    @State private var rating: Int = 5
    @State private var review: String = ""
    @State private var finishedDate = Date()
    
    // 읽고 있는 책용
    @State private var readingType: ReadingType = .paperBook
    @State private var dueDate: Date?
    @State private var progressPercentage: Int = 0
    @State private var memo: String = ""
    
    // 읽다 만 책용
    @State private var dropReason: String = ""
    @State private var droppedProgressPercentage: Int = 0
    
    // 위시리스트용
    @State private var wishlistMemo: String = ""
    
    let bookStatus: BookStatus
    
    var body: some View {
        NavigationStack {
            Form {
                // 책 선택 섹션
                Section {
                    if let book = selectedBook {
                        HStack {
                            AsyncImage(url: URL(string: book.cover ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .overlay {
                                        Image(systemName: "book.closed")
                                            .foregroundColor(.secondary)
                                    }
                            }
                            .frame(width: 60, height: 80)
                            .cornerRadius(6)
                            .clipped()
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(book.title)
                                    .font(.system(size: 16, weight: .semibold))
                                if let author = book.author {
                                    Text(author)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button {
                                showingBookSearch = true
                            } label: {
                                Text("변경")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        Button(action: {
                            showingBookSearch = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 15))
                                    .foregroundColor(.blue)
                                Text("책 검색")
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 3)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("책 선택")
                }
                
                // 상태별 입력 필드
                if bookStatus == .completed {
                    // 완독한 책
                    Section {
                        // 별점
                        VStack(alignment: .leading, spacing: 8) {
                            Text("별점")
                                .font(.system(size: 14, weight: .semibold))
                            
                            HStack(spacing: 8) {
                                ForEach(1...5, id: \.self) { index in
                                    Button(action: {
                                        rating = index
                                    }) {
                                        Image(systemName: index <= rating ? "star.fill" : "star")
                                            .font(.system(size: 30))
                                            .foregroundColor(index <= rating ? .yellow : .gray)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        // 한줄평
                        TextField("한줄평을 입력하세요", text: $review, axis: .vertical)
                            .lineLimit(3...6)
                        
                        // 완독일
                        DatePicker("완독일", selection: $finishedDate, displayedComponents: .date)
                    } header: {
                        Text("독서 정보")
                    }
                } else if bookStatus == .currentlyReading {
                    // 읽고 있는 책
                    Section {
                        Picker("읽기 형태", selection: $readingType) {
                            Text("종이책 소장").tag(ReadingType.paperBook)
                            Text("도서관 대여").tag(ReadingType.libraryRental)
                            Text("밀리의 서재").tag(ReadingType.millie)
                            Text("전자책 소장").tag(ReadingType.eBook)
                        }
                        
                        if readingType == .libraryRental {
                            DatePicker("대여 종료일", selection: Binding(
                                get: { dueDate ?? Date() },
                                set: { dueDate = $0 }
                            ), displayedComponents: .date)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("진행률: \(progressPercentage)%")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            
                            Slider(value: Binding(
                                get: { Double(progressPercentage) },
                                set: { progressPercentage = Int($0) }
                            ), in: 0...100, step: 1)
                        }
                        
                        TextField("메모", text: $memo, axis: .vertical)
                            .lineLimit(3...6)
                    } header: {
                        Text("읽기 정보")
                    }
                } else if bookStatus == .dropped {
                    // 읽다 만 책
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("진행률: \(droppedProgressPercentage)%")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            
                            Slider(value: Binding(
                                get: { Double(droppedProgressPercentage) },
                                set: { droppedProgressPercentage = Int($0) }
                            ), in: 0...100, step: 1)
                        }
                        
                        TextField("중단 이유", text: $dropReason, axis: .vertical)
                            .lineLimit(3...6)
                    } header: {
                        Text("중단 정보")
                    }
                } else if bookStatus == .wishlist {
                    // 위시리스트
                    Section {
                        TextField("메모", text: $wishlistMemo, axis: .vertical)
                            .lineLimit(3...6)
                    } header: {
                        Text("메모")
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("책 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        saveBook()
                    }
                    .disabled(selectedBook == nil || isLoading)
                }
            }
            .sheet(isPresented: $showingBookSearch) {
                BookSearchView(selectedBook: $selectedBook)
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
    
    private func saveBook() {
        guard let book = selectedBook else { return }
        isLoading = true
        errorMessage = nil
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        switch bookStatus {
        case .completed:
            let request = BookCreateRequest(
                title: book.title,
                author: book.author,
                coverImage: book.cover,
                rating: rating > 0 ? rating : 1,
                review: review.isEmpty ? nil : review,
                finishedDate: dateFormatter.string(from: finishedDate)
            )
            
            BookService.shared.addBook(request)
                .sink(
                    receiveCompletion: { completion in
                        isLoading = false
                        if case .failure(let error) = completion {
                            errorMessage = "책 추가 실패: \(error.localizedDescription)"
                        } else {
                            dismiss()
                        }
                    },
                    receiveValue: { _ in
                        dismiss()
                    }
                )
                .store(in: &cancellables)
            
        case .currentlyReading:
            let request = CurrentlyReadingCreateRequest(
                title: book.title,
                author: book.author,
                coverImage: book.cover,
                publisher: book.publisher,
                publishedDate: book.pubDate,
                description: book.description,
                readingType: readingType,
                dueDate: dueDate != nil ? dateFormatter.string(from: dueDate!) : nil,
                progressPercentage: progressPercentage,
                memo: memo.isEmpty ? nil : memo
            )
            
            CurrentlyReadingService.shared.addCurrentlyReading(request)
                .sink(
                    receiveCompletion: { completion in
                        isLoading = false
                        if case .failure(let error) = completion {
                            errorMessage = "책 추가 실패: \(error.localizedDescription)"
                        } else {
                            dismiss()
                        }
                    },
                    receiveValue: { _ in
                        dismiss()
                    }
                )
                .store(in: &cancellables)
            
        case .dropped:
            let request = DroppedBookCreateRequest(
                title: book.title,
                author: book.author,
                isbn: book.isbn,
                coverImage: book.cover,
                publisher: book.publisher,
                publishedDate: book.pubDate,
                description: book.description,
                readingType: nil,
                progressPercentage: droppedProgressPercentage,
                dropReason: dropReason.isEmpty ? nil : dropReason,
                startedDate: nil,
                droppedDate: dateFormatter.string(from: Date())
            )
            
            DroppedBookService.shared.addDroppedBook(request)
                .sink(
                    receiveCompletion: { completion in
                        isLoading = false
                        if case .failure(let error) = completion {
                            errorMessage = "책 추가 실패: \(error.localizedDescription)"
                        } else {
                            dismiss()
                        }
                    },
                    receiveValue: { _ in
                        dismiss()
                    }
                )
                .store(in: &cancellables)
            
        case .wishlist:
            let request = WishlistCreateRequest(
                title: book.title,
                author: book.author,
                coverImage: book.cover,
                publisher: book.publisher,
                publishedDate: book.pubDate,
                description: book.description,
                memo: wishlistMemo.isEmpty ? nil : wishlistMemo
            )
            
            WishlistService.shared.addWishlist(request)
                .sink(
                    receiveCompletion: { completion in
                        isLoading = false
                        if case .failure(let error) = completion {
                            errorMessage = "책 추가 실패: \(error.localizedDescription)"
                        } else {
                            dismiss()
                        }
                    },
                    receiveValue: { _ in
                        dismiss()
                    }
                )
                .store(in: &cancellables)
        }
    }
}

#Preview {
    AddBookView(bookStatus: .completed)
}
