//
//  BookDetailModal.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import SwiftUI
import Combine

struct BookDetailModal: View {
    let book: Book
    @Environment(\.dismiss) var dismiss
    @State private var showingEdit = false
    @State private var showingDeleteAlert = false
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
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
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary)
                            }
                    }
                    .frame(height: 100)
                    .cornerRadius(12)
                    .clipped()
                    .padding(.horizontal, 16)
                    
                    // 책 정보
                    VStack(alignment: .leading, spacing: 12) {
                        Text(book.title)
                            .font(.system(size: 15, weight: .bold))
                        
                        if let author = book.author {
                            Text(author)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        // 별점
                        if book.rating > 0 {
                            HStack(spacing: 4) {
                                ForEach(1...5, id: \.self) { index in
                                    Image(systemName: index <= book.rating ? "star.fill" : "star")
                                        .font(.system(size: 20))
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                        
                        // 완독일
                        if !book.finishedDate.isEmpty {
                            HStack {
                                Text("완독일:")
                                    .foregroundColor(.secondary)
                                Text(book.finishedDate)
                            }
                            .font(.system(size: 13))
                        }
                        
                        // 한줄평
                        if let review = book.review {
                            Divider()
                            Text("한줄평")
                                .font(.system(size: 14, weight: .semibold))
                            Text(review)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    
                    // 삭제 버튼
                    HStack {
                        Spacer()
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "trash")
                                Text("삭제")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.red)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("책 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingEdit = true
                    }) {
                        Text("편집")
                            .font(.system(size: 16))
                    }
                }
            }
            .sheet(isPresented: $showingEdit) {
                EditBookView(book: book)
            }
            .alert("책 삭제", isPresented: $showingDeleteAlert) {
                Button("취소", role: .cancel) {}
                Button("삭제", role: .destructive) {
                    deleteBook()
                }
            } message: {
                Text("정말로 이 책을 삭제하시겠습니까?")
            }
        }
    }
    
    private func deleteBook() {
        BookService.shared.deleteBook(id: book.id)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("책 삭제 실패: \(error)")
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

struct EditBookView: View {
    let book: Book
    @Environment(\.dismiss) var dismiss
    @State private var rating: Int
    @State private var review: String
    @State private var finishedDate: Date
    @State private var isLoading = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var errorMessage: String?
    
    init(book: Book) {
        self.book = book
        _rating = State(initialValue: book.rating)
        _review = State(initialValue: book.review ?? "")
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let date = formatter.date(from: book.finishedDate) ?? Date()
        _finishedDate = State(initialValue: date)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // 별점
                    VStack(alignment: .leading, spacing: 8) {
                        Text("별점")
                            .font(.system(size: 16, weight: .semibold))
                        
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { index in
                                Button {
                                    rating = index
                                } label: {
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
            }
            .navigationTitle("책 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        updateBook()
                    }
                    .disabled(isLoading)
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
    
    private func updateBook() {
        isLoading = true
        errorMessage = nil
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let finishedDateString = formatter.string(from: finishedDate)
        
        let request = BookUpdateRequest(
            title: book.title,
            author: book.author,
            coverImage: book.coverImage,
            rating: rating > 0 ? rating : 1,
            review: review.isEmpty ? nil : review,
            finishedDate: finishedDateString
        )
        
        BookService.shared.updateBook(id: book.id, book: request)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = "책 수정 실패: \(error.localizedDescription)"
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

#Preview {
    BookDetailModal(book: Book(
        id: 1,
        title: "테스트 책",
        author: "테스트 저자",
        coverImage: nil,
        rating: 5,
        review: "좋은 책이었습니다",
        finishedDate: "2024-01-01",
        createdAt: "",
        updatedAt: "",
        status: .completed,
        user: nil
    ))
}

