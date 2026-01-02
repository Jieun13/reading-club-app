//
//  CurrentlyReadingDetailModal.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import SwiftUI
import Combine
import Foundation

struct CurrentlyReadingDetailModal: View {
    let book: CurrentlyReading
    @Environment(\.dismiss) var dismiss
    @State private var showingEdit = false
    @State private var showingDeleteAlert = false
    @State private var showingDropModal = false
    @State private var showingCompleteModal = false
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
                        
                        // 읽기 타입
                        HStack {
                            Text("읽기 타입:")
                                .foregroundColor(.secondary)
                            Text(book.readingTypeDisplay ?? book.readingType)
                        }
                        .font(.system(size: 14))
                        
                        // 진행률
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("진행률")
                                    .font(.system(size: 14, weight: .semibold))
                                Spacer()
                                Text("\(book.progressPercentage)%")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                            
                            ProgressView(value: Double(book.progressPercentage), total: 100)
                                .tint(.blue)
                        }
                        
                        // 마감일
                        if let dueDate = book.dueDate {
                            HStack {
                                Text("목표일:")
                                    .foregroundColor(.secondary)
                                Text(dueDate)
                                if book.isOverdue == true {
                                    Text("(지연)")
                                        .foregroundColor(.red)
                                        .font(.system(size: 12, weight: .semibold))
                                }
                            }
                            .font(.system(size: 14))
                        }
                        
                        // 메모
                        if let memo = book.memo, !memo.isEmpty {
                            Divider()
                            Text("메모")
                                .font(.system(size: 16, weight: .semibold))
                            Text(memo)
                                .font(.system(size: 15))
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
                        
                        // 읽기 중단 버튼
                        Button {
                            showingDropModal = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "pause.circle.fill")
                                Text("읽기 중단")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange, lineWidth: 1)
                            )
                        }
                        
                        // 읽기 완료 버튼
                        Button {
                            showingCompleteModal = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("읽기 완료")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("읽고 있는 책")
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
                EditCurrentlyReadingView(book: book)
            }
            .sheet(isPresented: $showingDropModal) {
                DropBookModal(book: book) { dropReason, progressPercentage in
                    moveToDropped(dropReason: dropReason, progressPercentage: progressPercentage)
                }
            }
            .sheet(isPresented: $showingCompleteModal) {
                CompleteBookModal(book: book) { rating, review, finishedDate in
                    moveToCompleted(rating: rating, review: review, finishedDate: finishedDate)
                }
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
    
    private func moveToDropped(dropReason: String, progressPercentage: Int) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        // startedDate는 읽기 시작한 날짜 (createdAt에서 추출)
        let startedDate: String?
        if let createdAt = book.createdAt.components(separatedBy: "T").first {
            startedDate = createdAt
        } else {
            startedDate = formatter.string(from: Date())
        }
        
        // droppedDate는 오늘 날짜
        let droppedDate = formatter.string(from: Date())
        
        let request = DroppedBookCreateRequest(
            title: book.title,
            author: book.author,
            isbn: nil,
            coverImage: book.coverImage,
            publisher: book.publisher,
            publishedDate: book.publishedDate,
            description: book.description,
            readingType: book.readingType,
            progressPercentage: progressPercentage,
            dropReason: dropReason.isEmpty ? nil : dropReason,
            startedDate: startedDate,
            droppedDate: droppedDate
        )
        
        DroppedBookService.shared.addDroppedBook(request)
            .flatMap { _ in
                CurrentlyReadingService.shared.deleteCurrentlyReading(id: self.book.id)
            }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("읽기 중단 실패: \(error)")
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
    
    private func moveToCompleted(rating: Int, review: String?, finishedDate: String) {
        let request = BookCreateRequest(
            title: book.title,
            author: book.author,
            coverImage: book.coverImage,
            rating: rating,
            review: review,
            finishedDate: finishedDate
        )
        
        BookService.shared.addBook(request)
            .flatMap { _ in
                CurrentlyReadingService.shared.deleteCurrentlyReading(id: self.book.id)
            }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("읽기 완료 실패: \(error)")
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
        CurrentlyReadingService.shared.deleteCurrentlyReading(id: book.id)
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

struct EditCurrentlyReadingView: View {
    let book: CurrentlyReading
    @Environment(\.dismiss) var dismiss
    @State private var progressPercentage: Int
    @State private var memo: String
    @State private var dueDate: Date?
    @State private var isLoading = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var errorMessage: String?
    
    init(book: CurrentlyReading) {
        self.book = book
        _progressPercentage = State(initialValue: book.progressPercentage)
        _memo = State(initialValue: book.memo ?? "")
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let date = formatter.date(from: book.dueDate ?? "")
        _dueDate = State(initialValue: date)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // 진행률
                    VStack(alignment: .leading, spacing: 8) {
                        Text("진행률: \(progressPercentage)%")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Slider(value: Binding(
                            get: { Double(progressPercentage) },
                            set: { progressPercentage = Int($0) }
                        ), in: 0...100, step: 1)
                        
                        HStack {
                            Button("0%") { progressPercentage = 0 }
                            Button("25%") { progressPercentage = 25 }
                            Button("50%") { progressPercentage = 50 }
                            Button("75%") { progressPercentage = 75 }
                            Button("100%") { progressPercentage = 100 }
                        }
                        .buttonStyle(.bordered)
                        .font(.system(size: 12))
                    }
                    
                    // 메모
                    TextField("메모를 입력하세요", text: $memo, axis: .vertical)
                        .lineLimit(3...6)
                    
                    // 목표일
                    if let dueDate = dueDate {
                        DatePicker("목표일", selection: Binding(
                            get: { dueDate },
                            set: { self.dueDate = $0 }
                        ), displayedComponents: .date)
                    } else {
                        Button("목표일 추가") {
                            dueDate = Date()
                        }
                    }
                } header: {
                    Text("독서 정보")
                }
            }
            .navigationTitle("읽고 있는 책 수정")
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
        let dueDateString = dueDate.map { formatter.string(from: $0) }
        
        let readingType = ReadingType(rawValue: book.readingType) ?? .paperBook
        
        let request = CurrentlyReadingUpdateRequest(
            title: book.title,
            author: book.author,
            coverImage: book.coverImage,
            publisher: book.publisher,
            publishedDate: book.publishedDate,
            description: book.description,
            readingType: readingType,
            dueDate: dueDateString,
            progressPercentage: progressPercentage,
            memo: memo.isEmpty ? nil : memo
        )
        
        CurrentlyReadingService.shared.updateCurrentlyReading(id: book.id, book: request)
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

// 읽기 중단 모달
struct DropBookModal: View {
    let book: CurrentlyReading
    let onConfirm: (String, Int) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var dropReason = ""
    @State private var progressPercentage: Int
    
    init(book: CurrentlyReading, onConfirm: @escaping (String, Int) -> Void) {
        self.book = book
        self.onConfirm = onConfirm
        _progressPercentage = State(initialValue: book.progressPercentage)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // 진행률
                    VStack(alignment: .leading, spacing: 8) {
                        Text("중단 시 진행률: \(progressPercentage)%")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Slider(value: Binding(
                            get: { Double(progressPercentage) },
                            set: { progressPercentage = Int($0) }
                        ), in: 0...100, step: 1)
                        
                        HStack {
                            Button("0%") { progressPercentage = 0 }
                            Button("25%") { progressPercentage = 25 }
                            Button("50%") { progressPercentage = 50 }
                            Button("75%") { progressPercentage = 75 }
                            Button("100%") { progressPercentage = 100 }
                        }
                        .buttonStyle(.bordered)
                        .font(.system(size: 12))
                    }
                    
                    // 중단 사유
                    TextField("중단 사유를 입력하세요", text: $dropReason, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("읽기 중단 정보")
                }
            }
            .navigationTitle("읽기 중단")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("확인") {
                        onConfirm(dropReason, progressPercentage)
                        dismiss()
                    }
                }
            }
        }
    }
}

// 읽기 완료 모달
struct CompleteBookModal: View {
    let book: CurrentlyReading
    let onConfirm: (Int, String?, String) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var rating = 5
    @State private var review = ""
    @State private var finishedDate = Date()
    
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
                    
                    // 완독일
                    DatePicker("완독일", selection: $finishedDate, displayedComponents: .date)
                    
                    // 한줄평
                    TextField("한줄평을 입력하세요", text: $review, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("완독 정보")
                }
            }
            .listStyle(.plain)
            .navigationTitle("읽기 완료")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("확인") {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        let dateString = formatter.string(from: finishedDate)
                        onConfirm(rating, review.isEmpty ? nil : review, dateString)
                        dismiss()
                    }
                }
            }
        }
    }
}
