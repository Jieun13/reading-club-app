//
//  ProfileView.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import SwiftUI
import Combine

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showingLogoutAlert = false
    @State private var statistics: UserStatistics?
    @State private var completedBooks: [Book] = []
    @State private var currentlyReading: [CurrentlyReading] = []
    @State private var droppedBooks: [DroppedBook] = []
    @State private var wishlists: [Wishlist] = []
    @State private var isLoading = false
    @State private var cancellables = Set<AnyCancellable>()
    
    private var totalBooks: Int {
        return completedBooks.count
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 프로필 헤더
                    VStack(spacing: 16) {
                        // 프로필 이미지
                        ProfileImage(imageUrl: authService.currentUser?.profileImage, size: 100)
                        
                        // 닉네임
                        Text(authService.currentUser?.nickname ?? "사용자")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)
                        
                        // 가입일
                        if let createdAt = authService.currentUser?.createdAt {
                            Text("가입일: \(formatDate(createdAt))")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                    
                    // 통계 섹션
                    VStack(alignment: .leading, spacing: 12) {
                        Text("독서 현황")
                            .font(.system(size: 16, weight: .semibold))
                            .padding(.horizontal, 16)
                        
                        HStack(spacing: 12) {
                            StatItem(title: "전체 책", value: "\(totalBooks)")
                            StatItem(title: "읽는 중", value: "\(currentlyReading.count)")
                            StatItem(title: "위시리스트", value: "\(wishlists.count)")
                            StatItem(title: "읽다 만 책", value: "\(droppedBooks.count)")
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // 읽고 있는 책 섹션
                    if !currentlyReading.isEmpty {
                        SectionView(title: "읽고 있는 책") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(currentlyReading.prefix(10)) { book in
                                        BookThumbnailCard(
                                            coverImage: book.coverImage,
                                            title: book.title
                                        )
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    
                    // 설정 섹션
                    VStack(spacing: 0) {
                        NavigationLink(destination: EditProfileView()) {
                            SettingsRow(icon: "person.circle", title: "프로필 수정")
                        }
                        
                        Divider()
                            .padding(.leading, 50)
                        
                        Button(action: {
                            showingLogoutAlert = true
                        }) {
                            SettingsRow(icon: "arrow.right.square", title: "로그아웃", color: .red)
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("프로필")
            .navigationBarTitleDisplayMode(.inline)
            .alert("로그아웃", isPresented: $showingLogoutAlert) {
                Button("취소", role: .cancel) {}
                Button("로그아웃", role: .destructive) {
                    authService.logout()
                }
            } message: {
                Text("정말 로그아웃 하시겠습니까?")
            }
            .onAppear {
                loadProfileData()
            }
        }
    }
    
    private func loadProfileData() {
        isLoading = true
        
        let group = DispatchGroup()
        
        // 완독한 책
        group.enter()
        BookService.shared.getBooks(page: 0, size: 100)
            .sink(
                receiveCompletion: { _ in group.leave() },
                receiveValue: { response in
                    completedBooks = response.content
                }
            )
            .store(in: &cancellables)
        
        // 읽고 있는 책
        group.enter()
        CurrentlyReadingService.shared.getCurrentlyReading(page: 0, size: 1000)
            .sink(
                receiveCompletion: { _ in group.leave() },
                receiveValue: { response in
                    currentlyReading = response.content
                }
            )
            .store(in: &cancellables)
        
        // 읽다 만 책
        group.enter()
        DroppedBookService.shared.getDroppedBooks(page: 0, size: 1000)
            .sink(
                receiveCompletion: { _ in group.leave() },
                receiveValue: { response in
                    droppedBooks = response.content
                }
            )
            .store(in: &cancellables)
        
        // 위시리스트
        group.enter()
        WishlistService.shared.getWishlists(page: 0, size: 1000)
            .sink(
                receiveCompletion: { _ in group.leave() },
                receiveValue: { response in
                    wishlists = response.content
                }
            )
            .store(in: &cancellables)
        
        // 통계 API (참고용)
        UserService.shared.getMyStatistics()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { stats in
                    statistics = stats
                }
            )
            .store(in: &cancellables)
        
        group.notify(queue: .main) {
            isLoading = false
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        // TODO: 날짜 포맷팅
        return dateString
    }
}

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct SectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .padding(.horizontal, 16)
            
            content
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    var color: Color = .primary
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(color)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}


struct BookThumbnailCard: View {
    let coverImage: String?
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            BookCoverImage(imageUrl: coverImage, width: 80, height: 120, cornerRadius: 6)
            
            Text(title)
                .font(.system(size: 10))
                .lineLimit(2)
                .frame(width: 80)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthService.shared)
}

