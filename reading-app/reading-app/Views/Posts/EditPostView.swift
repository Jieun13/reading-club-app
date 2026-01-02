//
//  EditPostView.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import SwiftUI
import Combine

struct EditPostView: View {
    let post: Post
    @Environment(\.dismiss) var dismiss
    @State private var selectedPostType: PostType
    @State private var selectedBook: BookSearchResult?
    @State private var showingBookSearch = false
    @State private var title: String
    @State private var content: String
    @State private var isRecommendation: Bool
    @State private var quotes: [QuoteItem]
    @State private var isPublic: Bool
    @State private var isLoading = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var errorMessage: String?
    
    struct QuoteItem: Identifiable {
        let id = UUID()
        var text: String
        var page: String
    }
    
    init(post: Post) {
        self.post = post
        _selectedPostType = State(initialValue: post.postType)
        
        // BookInfo에서 BookSearchResult 생성
        let bookInfo = post.bookInfo
        let bookSearchResult = BookSearchResult(
            title: bookInfo.title,
            author: bookInfo.author.isEmpty ? nil : bookInfo.author,
            publisher: bookInfo.publisher.isEmpty ? nil : bookInfo.publisher,
            pubDate: bookInfo.pubDate.isEmpty ? nil : bookInfo.pubDate,
            description: nil,
            cover: bookInfo.cover.isEmpty ? nil : bookInfo.cover,
            isbn: bookInfo.isbn.isEmpty ? nil : bookInfo.isbn,
            categoryName: nil,
            priceStandard: nil
        )
        _selectedBook = State(initialValue: bookSearchResult)
        _title = State(initialValue: post.title ?? "")
        _content = State(initialValue: post.content ?? post.reason ?? "")
        _isRecommendation = State(initialValue: post.recommendationType == "RECOMMEND")
        _quotes = State(initialValue: (post.quotes ?? []).map { QuoteItem(text: $0.text, page: $0.page) })
        _isPublic = State(initialValue: post.visibility == "PUBLIC")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // 게시글 타입 선택 (읽기 전용)
                Section {
                    Picker("게시글 타입", selection: .constant(selectedPostType)) {
                        ForEach(PostType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .disabled(true)
                } header: {
                    Text("게시글 타입")
                }
                
                // 책 선택
                Section {
                    if let book = selectedBook {
                        HStack {
                            BookCoverImage(imageUrl: book.cover, width: 60, height: 80, cornerRadius: 6)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(book.title)
                                    .font(.system(size: 15, weight: .semibold))
                                if let author = book.author {
                                    Text(author)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button {
                                showingBookSearch = true
                            } label: {
                                Text("변경")
                                    .font(.system(size: 13))
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
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                                Text("책 검색")
                                    .font(.system(size: 15))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("책 선택")
                }
                
                // 게시글 내용
                Section {
                    if selectedPostType == .review {
                        // 독후감
                        TextField("제목", text: $title)
                        TextField("내용을 입력하세요", text: $content, axis: .vertical)
                            .lineLimit(10...20)
                    } else if selectedPostType == .recommendation {
                        // 추천/비추천
                        Picker("", selection: $isRecommendation) {
                            Text("추천").tag(true)
                            Text("비추천").tag(false)
                        }
                        .pickerStyle(.segmented)
                        
                        TextField("추천 이유를 입력하세요", text: $content, axis: .vertical)
                            .lineLimit(5...15)
                    } else if selectedPostType == .quote {
                        // 문장 수집
                        ForEach(Array(quotes.enumerated()), id: \.element.id) { index, quote in
                            VStack(alignment: .leading, spacing: 8) {
                                TextField("문장", text: Binding(
                                    get: { quotes[index].text },
                                    set: { newValue in
                                        quotes[index].text = newValue
                                    }
                                ), axis: .vertical)
                                .lineLimit(3...6)
                                
                                TextField("페이지", text: Binding(
                                    get: { quotes[index].page },
                                    set: { newValue in
                                        quotes[index].page = newValue
                                    }
                                ))
                                .keyboardType(.numberPad)
                            }
                        }
                        .onDelete { indexSet in
                            quotes.remove(atOffsets: indexSet)
                        }
                        
                        Button(action: {
                            quotes.append(QuoteItem(text: "", page: ""))
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("문장 추가")
                            }
                            .foregroundColor(.blue)
                        }
                    }
                } header: {
                    Text("게시글 내용")
                }
                
                // 공개 설정
                Section {
                    Toggle("공개", isOn: $isPublic)
                } header: {
                    Text("공개 설정")
                } footer: {
                    Text(isPublic ? "모든 사용자가 이 게시글을 볼 수 있습니다." : "나만 볼 수 있습니다.")
                }
            }
            .listStyle(.plain)
            .navigationTitle("게시글 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        updatePost()
                    }
                    .disabled(isLoading || !isValidInput)
                }
            }
            .sheet(isPresented: $showingBookSearch) {
                BookSearchView(selectedBook: $selectedBook)
            }
            .onChange(of: selectedPostType) { _ in
                if selectedPostType == .quote && quotes.isEmpty {
                    quotes.append(QuoteItem(text: "", page: ""))
                }
            }
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
            )
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
    
    private var isValidInput: Bool {
        guard selectedBook != nil else { return false }
        
        switch selectedPostType {
        case .review:
            return !title.isEmpty && !content.isEmpty
        case .recommendation:
            return !content.isEmpty
        case .quote:
            let validQuotes = quotes.filter { !$0.text.trimmingCharacters(in: .whitespaces).isEmpty && !$0.page.isEmpty }
            return !validQuotes.isEmpty
        }
    }
    
    private func updatePost() {
        guard let book = selectedBook else { return }
        
        // 타입별 유효성 검사
        switch selectedPostType {
        case .review:
            guard !title.isEmpty, !content.isEmpty else { return }
        case .recommendation:
            guard !content.isEmpty else { return }
        case .quote:
            let validQuotes = quotes.filter { !$0.text.trimmingCharacters(in: .whitespaces).isEmpty && !$0.page.isEmpty }
            guard !validQuotes.isEmpty else {
                errorMessage = "문장과 페이지를 입력해주세요."
                isLoading = false
                return
            }
        }
        
        isLoading = true
        errorMessage = nil
        
        let bookInfo = BookInfo(
            isbn: book.isbn ?? "",
            title: book.title,
            author: book.author ?? "",
            publisher: book.publisher ?? "",
            cover: book.cover ?? "",
            pubDate: book.pubDate ?? "",
            description: book.description
        )
        
        let request = CreatePostRequest(
            bookInfo: bookInfo,
            postType: selectedPostType,
            visibility: isPublic ? .public : .private,
            title: selectedPostType == .review ? title : nil,
            content: selectedPostType == .review ? content : (selectedPostType == .recommendation ? content : nil),
            recommendationType: selectedPostType == .recommendation ? (isRecommendation ? .recommend : .notRecommend) : nil,
            reason: selectedPostType == .recommendation ? content : nil,
            quotes: selectedPostType == .quote ? {
                let filtered = quotes.filter { !$0.text.trimmingCharacters(in: .whitespaces).isEmpty && !$0.page.isEmpty }
                let sorted = filtered.sorted { (Int($0.page) ?? 0) < (Int($1.page) ?? 0) }
                return sorted.map { Quote(page: $0.page, text: $0.text) }
            }() : nil,
            quote: nil,
            pageNumber: nil
        )
        
        PostService.shared.updatePost(id: post.id, post: request)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = "게시글 수정 실패: \(error.localizedDescription)"
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
    EditPostView(post: Post(
        id: 1,
        userId: 1,
        userName: "테스트 유저",
        userProfileImage: nil,
        postType: .review,
        visibility: "PUBLIC",
        bookInfo: BookInfo(
            isbn: "1234567890",
            title: "테스트 책",
            author: "테스트 저자",
            publisher: "테스트 출판사",
            cover: "",
            pubDate: "2024-01-01",
            description: nil
        ),
        createdAt: "",
        updatedAt: "",
        commentCount: 0,
        title: "테스트 제목",
        content: "테스트 게시글 내용입니다.",
        recommendationType: nil,
        reason: nil,
        quotes: nil,
        quote: nil,
        pageNumber: nil
    ))
}
