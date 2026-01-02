//
//  StatisticsView.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import SwiftUI
import Combine

struct StatisticsView: View {
    @State private var statistics: UserStatistics?
    @State private var monthlyStats: [MonthlyStats] = []
    @State private var recentBooks: [Book] = []
    @State private var allBooks: [Book] = []
    @State private var allPosts: [Post] = []
    @State private var isLoading = false
    @State private var cancellables = Set<AnyCancellable>()
    
    private var actualTotalBooks: Int {
        return allBooks.count
    }
    
    private var actualTotalPosts: Int {
        return allPosts.count
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if isLoading && statistics == nil {
                        ProgressView()
                            .frame(height: 400)
                    } else {
                        // 기본 통계 카드 (2x3 그리드)
                        VStack(spacing: 12) {
                            // 첫 번째 줄
                            HStack(spacing: 12) {
                                StatisticsCard(
                                    title: "전체 책 수",
                                    value: "\(actualTotalBooks)",
                                    icon: "books.vertical.fill",
                                    color: .blue
                                )
                                
                                StatisticsCard(
                                    title: "평균 별점",
                                    value: String(format: "%.1f", calculateAverageRating()),
                                    icon: "star.fill",
                                    color: .yellow
                                )
                            }
                            
                            // 두 번째 줄
                            HStack(spacing: 12) {
                                StatisticsCard(
                                    title: "올해 완독",
                                    value: "\(calculateThisYearBooks())",
                                    icon: "calendar",
                                    color: .green
                                )
                                
                                StatisticsCard(
                                    title: "이번달 완독",
                                    value: "\(statistics?.thisMonthBooks ?? 0)",
                                    icon: "checkmark.circle.fill",
                                    color: .orange
                                )
                            }
                            
                            // 세 번째 줄
                            HStack(spacing: 12) {
                                StatisticsCard(
                                    title: "월평균 완독",
                                    value: String(format: "%.1f", calculateMonthlyAverage()),
                                    icon: "chart.bar.fill",
                                    color: .purple
                                )
                                
                                StatisticsCard(
                                    title: "작성한 게시글",
                                    value: "\(actualTotalPosts)",
                                    icon: "square.and.pencil",
                                    color: .pink
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        
                        // 별점 분포
                        VStack(alignment: .leading, spacing: 12) {
                            Text("별점 분포")
                                .font(.system(size: 16, weight: .semibold))
                                .padding(.horizontal, 16)
                            
                            VStack(spacing: 8) {
                                ForEach(1...5, id: \.self) { rating in
                                    RatingDistributionRow(
                                        rating: rating,
                                        count: getRatingCount(rating: rating),
                                        total: allBooks.filter { $0.rating > 0 }.count
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.top, 8)
                        
                        // 최근 완독한 책
                        VStack(alignment: .leading, spacing: 12) {
                            Text("최근 완독한 책")
                                .font(.system(size: 16, weight: .semibold))
                                .padding(.horizontal, 16)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(recentBooks.prefix(5)) { book in
                                        VStack(alignment: .leading, spacing: 4) {
                                            BookCoverImage(imageUrl: book.coverImage, width: 80, height: 120, cornerRadius: 8)
                                            
                                            Text(book.title)
                                                .font(.system(size: 11))
                                                .lineLimit(2)
                                                .frame(width: 80)
                                            
                                            if book.rating > 0 {
                                                HStack(spacing: 2) {
                                                    ForEach(1...5, id: \.self) { index in
                                                        Image(systemName: index <= book.rating ? "star.fill" : "star")
                                                            .font(.system(size: 8))
                                                            .foregroundColor(.yellow)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("통계")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadStatistics()
            }
        }
    }
    
    private func loadStatistics() {
        isLoading = true
        
        loadMonthlyStatistics()
        loadRecentBooks()
        loadAllPosts()
        
        // 통계 API는 참고용으로만 로드 (이번달 완독 등)
        UserService.shared.getMyStatistics()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { stats in
                    statistics = stats
                }
            )
            .store(in: &cancellables)
    }
    
    private func loadAllPosts() {
        PostService.shared.getMyPosts(page: 0, size: 1000)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { response in
                    allPosts = response.posts
                }
            )
            .store(in: &cancellables)
    }
    
    private func loadMonthlyStatistics() {
        let currentYear = Calendar.current.component(.year, from: Date())
        BookService.shared.getMonthlyStatistics()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { stats in
                    monthlyStats = stats.filter { $0.year == currentYear }
                }
            )
            .store(in: &cancellables)
    }
    
    private func loadRecentBooks() {
        BookService.shared.getBooks(page: 0, size: 100)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure = completion {
                        // 에러 처리
                    }
                },
                receiveValue: { response in
                    allBooks = response.content
                    
                    // 최근 완독한 책 5권 (finishedDate 기준 정렬)
                    recentBooks = allBooks.sorted { book1, book2 in
                        let date1 = parseDate(book1.finishedDate ?? "")
                        let date2 = parseDate(book2.finishedDate ?? "")
                        return date1 > date2
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func parseDate(_ dateString: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString) ?? Date.distantPast
    }
    
    private func calculateAverageRating() -> Double {
        guard !allBooks.isEmpty else { return 0.0 }
        let totalRating = allBooks.reduce(0) { $0 + $1.rating }
        return Double(totalRating) / Double(allBooks.count)
    }
    
    private func calculateMonthlyAverage() -> Double {
        guard !monthlyStats.isEmpty else { return 0.0 }
        let total = monthlyStats.reduce(0) { $0 + $1.count }
        return Double(total) / Double(monthlyStats.count)
    }
    
    private func calculateThisYearBooks() -> Int {
        let currentYear = Calendar.current.component(.year, from: Date())
        return monthlyStats.filter { $0.year == currentYear }.reduce(0) { $0 + $1.count }
    }
    
    private func getRatingCount(rating: Int) -> Int {
        return allBooks.filter { $0.rating == rating }.count
    }
}

struct StatisticsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct RatingDistributionRow: View {
    let rating: Int
    let count: Int
    let total: Int
    
    var percentage: Double {
        guard total > 0 else { return 0.0 }
        return Double(count) / Double(total) * 100.0
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 별점 표시
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= rating ? "star.fill" : "star")
                        .font(.system(size: 12))
                        .foregroundColor(index <= rating ? .yellow : .gray.opacity(0.3))
                }
            }
            .frame(width: 80, alignment: .leading)
            
            // 진행 바
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.yellow.opacity(0.6))
                        .frame(width: geometry.size.width * CGFloat(percentage / 100.0), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            // 개수와 퍼센트
            HStack(spacing: 4) {
                Text("\(count)")
                    .font(.system(size: 12, weight: .semibold))
                Text("(\(String(format: "%.0f", percentage))%)")
                    .font(.system(size: 11))
            }
            .foregroundColor(.secondary)
            .frame(width: 60, alignment: .trailing)
        }
    }
}

#Preview {
    StatisticsView()
}
