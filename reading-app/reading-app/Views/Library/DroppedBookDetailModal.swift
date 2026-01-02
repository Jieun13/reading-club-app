//
//  DroppedBookDetailModal.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import SwiftUI
import Combine

struct DroppedBookDetailModal: View {
    let book: DroppedBook
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
                        
                        if let publisher = book.publisher {
                            Text(publisher)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        // 진행률
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("중단 시 진행률")
                                    .font(.system(size: 14, weight: .semibold))
                                Spacer()
                                Text("\(book.progressPercentage)%")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.orange)
                            }
                            
                            ProgressView(value: Double(book.progressPercentage), total: 100)
                                .tint(.orange)
                        }
                        
                        // 중단 사유
                        if let dropReason = book.dropReason, !dropReason.isEmpty {
                            Divider()
                            Text("중단 사유")
                                .font(.system(size: 13, weight: .semibold))
                            Text(dropReason)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    
                    // 상태 변경 및 삭제 버튼
                    HStack(spacing: 12) {
                        // 삭제 버튼
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "trash")
                                Text("삭제")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                        }
                        
                        // 다시 읽기 버튼
                        Button {
                            resumeReading()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                Text("다시 읽기")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("읽다 만 책")
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
                EditDroppedBookView(book: book)
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
    
    private func resumeReading() {
        let readingType = ReadingType(rawValue: "PAPER_BOOK") ?? .paperBook
        
        let request = CurrentlyReadingCreateRequest(
            title: book.title,
            author: book.author,
            coverImage: book.coverImage,
            publisher: book.publisher,
            publishedDate: book.publishedDate,
            description: book.description,
            readingType: readingType,
            dueDate: nil,
            progressPercentage: book.progressPercentage,
            memo: nil
        )
        
        CurrentlyReadingService.shared.addCurrentlyReading(request)
            .flatMap { _ in
                DroppedBookService.shared.deleteDroppedBook(id: self.book.id)
            }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("다시 읽기 실패: \(error)")
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
    
    private func deleteBook() {
        DroppedBookService.shared.deleteDroppedBook(id: book.id)
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

struct EditDroppedBookView: View {
    let book: DroppedBook
    @Environment(\.dismiss) var dismiss
    @State private var progressPercentage: Int
    @State private var dropReason: String
    @State private var isLoading = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var errorMessage: String?
    
    init(book: DroppedBook) {
        self.book = book
        _progressPercentage = State(initialValue: book.progressPercentage)
        _dropReason = State(initialValue: book.dropReason ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // 진행률
                    VStack(alignment: .leading, spacing: 8) {
                        Text("중단 시 진행률: \(progressPercentage)%")
                            .font(.system(size: 14, weight: .semibold))
                        
                        Slider(value: Binding(
                            get: { Double(progressPercentage) },
                            set: { progressPercentage = Int($0) }
                        ), in: 0...100, step: 1)
                    }
                    
                    // 중단 사유
                    TextField("중단 사유를 입력하세요", text: $dropReason, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("독서 정보")
                }
            }
            .navigationTitle("읽다 만 책 수정")
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
        
        let request = DroppedBookUpdateRequest(
            dropReason: dropReason.isEmpty ? nil : dropReason,
            progressPercentage: progressPercentage
        )
        
        DroppedBookService.shared.updateDroppedBook(id: book.id, book: request)
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

