//
//  WishlistDetailModal.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import SwiftUI
import Combine
import Foundation

struct WishlistDetailModal: View {
    let book: Wishlist
    @Environment(\.dismiss) var dismiss
    @State private var showingEdit = false
    @State private var showingDeleteAlert = false
    @State private var showingStartReadingModal = false
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
                        
                        if let publishedDate = book.publishedDate {
                            Text("출간일: \(publishedDate)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        // 메모
                        if let memo = book.memo, !memo.isEmpty {
                            Divider()
                            Text("메모")
                                .font(.system(size: 13, weight: .semibold))
                            Text(memo)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        // 설명
                        if let description = book.description, !description.isEmpty {
                            Divider()
                            Text("책 소개")
                                .font(.system(size: 12, weight: .semibold))
                            Text(description)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
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
                        
                        // 읽는 중으로 추가 버튼
                        Button {
                            showingStartReadingModal = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "book.fill")
                                Text("읽는 중으로 추가")
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
            .navigationTitle("위시리스트")
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
                EditWishlistView(book: book)
            }
            .sheet(isPresented: $showingStartReadingModal) {
                StartReadingModal(book: book) { readingType, dueDate, progressPercentage, memo in
                    addToCurrentlyReading(readingType: readingType, dueDate: dueDate, progressPercentage: progressPercentage, memo: memo)
                }
            }
            .alert("책 삭제", isPresented: $showingDeleteAlert) {
                Button("취소", role: .cancel) {}
                Button("삭제", role: .destructive) {
                    deleteBook()
                }
            } message: {
                Text("정말로 이 책을 위시리스트에서 삭제하시겠습니까?")
            }
        }
    }
    
    private func addToCurrentlyReading(readingType: ReadingType, dueDate: String?, progressPercentage: Int, memo: String?) {
        let request = CurrentlyReadingCreateRequest(
            title: book.title,
            author: book.author,
            coverImage: book.coverImage,
            publisher: book.publisher,
            publishedDate: book.publishedDate,
            description: book.description,
            readingType: readingType,
            dueDate: dueDate,
            progressPercentage: progressPercentage,
            memo: memo
        )
        
        CurrentlyReadingService.shared.addCurrentlyReading(request)
            .flatMap { _ in
                WishlistService.shared.deleteWishlist(id: self.book.id)
            }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("읽는 중으로 추가 실패: \(error)")
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
        WishlistService.shared.deleteWishlist(id: book.id)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("위시리스트 삭제 실패: \(error)")
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

struct EditWishlistView: View {
    let book: Wishlist
    @Environment(\.dismiss) var dismiss
    @State private var memo: String
    @State private var isLoading = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var errorMessage: String?
    
    init(book: Wishlist) {
        self.book = book
        _memo = State(initialValue: book.memo ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Color.clear
                    .frame(height: 0)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                
                Section {
                    // 메모
                    TextField("메모를 입력하세요", text: $memo, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("위시리스트 정보")
                }
            }
            .navigationTitle("위시리스트 수정")
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
        
        let request = WishlistUpdateRequest(
            memo: memo.isEmpty ? nil : memo
        )
        
        WishlistService.shared.updateWishlist(id: book.id, wishlist: request)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = "위시리스트 수정 실패: \(error.localizedDescription)"
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

// 읽는 중으로 추가 모달
struct StartReadingModal: View {
    let book: Wishlist
    let onConfirm: (ReadingType, String?, Int, String?) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var readingType: ReadingType = .paperBook
    @State private var dueDate: Date?
    @State private var progressPercentage = 0
    @State private var memo = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // 읽기 타입
                    Picker("읽기 타입", selection: $readingType) {
                        ForEach([ReadingType.paperBook, .libraryRental, .millie, .eBook], id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    // 목표일
                    Toggle("목표일 설정", isOn: Binding(
                        get: { dueDate != nil },
                        set: { if $0 { dueDate = Date() } else { dueDate = nil } }
                    ))
                    
                    if let dueDate = dueDate {
                        DatePicker("목표일", selection: Binding(
                            get: { dueDate },
                            set: { self.dueDate = $0 }
                        ), displayedComponents: .date)
                    }
                    
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
                } header: {
                    Text("읽기 정보")
                }
            }
            .navigationTitle("읽는 중으로 추가")
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
                        let dueDateString = dueDate.map { formatter.string(from: $0) }
                        onConfirm(readingType, dueDateString, progressPercentage, memo.isEmpty ? nil : memo)
                        dismiss()
                    }
                }
            }
        }
    }
}
